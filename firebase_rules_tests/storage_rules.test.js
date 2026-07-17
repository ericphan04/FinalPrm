const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const fs = require('fs');
const path = require('path');

describe('Storage Security Rules', () => {
  let testEnv;

  before(async () => {
    testEnv = await initializeTestEnvironment({
      projectId: 'test-finalprm-project',
      storage: {
        rules: fs.readFileSync(path.resolve(__dirname, '../storage.rules'), 'utf8'),
        host: '127.0.0.1',
        port: 9199,
      },
    });
  });

  beforeEach(async () => {
    await testEnv.clearStorage();
  });

  after(async () => {
    await testEnv.cleanup();
  });

  describe('User Avatar Storage', () => {
    it('allows anyone (guests) to read user avatars', async () => {
      const guestStorage = testEnv.unauthenticatedContext().storage();
      const avatarRef = guestStorage.ref('users/user_1/avatar.jpg');
      await assertSucceeds(avatarRef.getDownloadURL().catch(e => {
        // rules-unit-testing might throw 404 because file doesn't exist,
        // but if permission was denied it throws 'storage/unauthorized'.
        // So we catch and check if it is NOT unauthorized.
        if (e.code === 'storage/unauthorized') throw e;
      }));
    });

    it('denies guests from uploading avatars', async () => {
      const guestStorage = testEnv.unauthenticatedContext().storage();
      const avatarRef = guestStorage.ref('users/user_1/avatar.jpg');
      await assertFails(avatarRef.put(Buffer.from('dummy_image'), { contentType: 'image/jpeg' }));
    });

    it('allows user to upload image to their own avatar path', async () => {
      const userStorage = testEnv.authenticatedContext('user_1').storage();
      const avatarRef = userStorage.ref('users/user_1/avatar.jpg');
      await assertSucceeds(avatarRef.put(Buffer.from('dummy_image'), { contentType: 'image/jpeg' }));
    });

    it('denies user from uploading image to other user\'s avatar path', async () => {
      const user1Storage = testEnv.authenticatedContext('user_1').storage();
      const avatarRef = user1Storage.ref('users/user_2/avatar.jpg');
      await assertFails(avatarRef.put(Buffer.from('dummy_image'), { contentType: 'image/jpeg' }));
    });

    it('denies user from uploading non-image content', async () => {
      const userStorage = testEnv.authenticatedContext('user_1').storage();
      const avatarRef = userStorage.ref('users/user_1/avatar.txt');
      await assertFails(avatarRef.put(Buffer.from('text data'), { contentType: 'text/plain' }));
    });

    it('denies user from uploading too large files (>= 5MB)', async () => {
      const userStorage = testEnv.authenticatedContext('user_1').storage();
      const avatarRef = userStorage.ref('users/user_1/avatar.jpg');
      const largeBuffer = Buffer.alloc(5 * 1024 * 1024 + 100); // slightly more than 5MB
      await assertFails(avatarRef.put(largeBuffer, { contentType: 'image/jpeg' }));
    });
  });
});
