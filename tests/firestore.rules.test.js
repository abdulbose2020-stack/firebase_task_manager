
const {
    initializeTestEnvironment,
    assertFails,
    assertSucceeds,
} = require('@firebase/rules-unit-testing');

const {
    doc,
    getDoc,
    updateDoc,
    deleteDoc,
    setDoc,
} = require('firebase/firestore');

const fs = require('node:fs');

async function runTest() {
    const testEnv = await initializeTestEnvironment({
        projectId: 'flutter-firebase-task-ma-dbd31',
        firestore: {
            host: '127.0.0.1',
            port: 8080,
            rules: fs.readFileSync('firestore.rules', 'utf8'),
        },
    });

    try {
        const guestB = testEnv.authenticatedContext(
            'ng6Vay7mpZ3rtzjDqcrSljcDSEhY'
        );
        const guestBDb = guestB.firestore();

        const guestA = testEnv.authenticatedContext(
            'EeMwymplGnO2Ds80h1riORuopil7'
        );
        const guestADb = guestA.firestore();

        const anonymousDb = testEnv.unauthenticatedContext().firestore();

        // Test 1: Guest A can read their own task.
        await assertSucceeds(
            getDoc(doc(guestADb, 'tasks/A1yiDITSuRAb94Cmh5aU'))
        );
        console.log('PASS: Guest A can read their own task.');

        // Test 2: Guest B cannot read Guest A's task.
        await assertFails(
            getDoc(doc(guestBDb, 'tasks/A1yiDITSuRAb94Cmh5aU'))
        );
        console.log('PASS: Guest B cannot read Guest A task.');

        // Test 3: Guest B cannot update Guest A's task.
        await assertFails(
            updateDoc(doc(guestBDb, 'tasks/A1yiDITSuRAb94Cmh5aU'), {
                title: 'Hacked by Guest B',
            })
        );
        console.log('PASS: Guest B cannot update Guest A task.');

        // Test 4: Guest B cannot delete Guest A's task.
        await assertFails(
            deleteDoc(doc(guestBDb, 'tasks/A1yiDITSuRAb94Cmh5aU'))
        );
        console.log('PASS: Guest B cannot delete Guest A task.');

        // Test 5: Guest B cannot create a task under Guest A's ownership.
        await assertFails(
            setDoc(doc(guestBDb, 'tasks/fakeTask'), {
                ownerId: 'EeMwymplGnO2Ds80h1riORuopil7',
                title: 'Pretending to be Guest A',
                completed: false,
                priority: 2,
            })
        );
        console.log(
            'PASS: Guest B cannot create a task under Guest A ownership.'
        );

        // Test 6: Unauthenticated users cannot read tasks.
        await assertFails(
            getDoc(doc(anonymousDb, 'tasks/A1yiDITSuRAb94Cmh5aU'))
        );
        console.log('PASS: Unauthenticated users cannot read tasks.');

    } finally {
        await testEnv.cleanup();
    }
}

runTest().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
