module.exports = async (promise, expectedError) => {
  try {
    await promise;
    assert.fail('Expected revert not received');
  } catch (error) {
    const revertFound = error.message.search('revert') >= 0;
    assert(revertFound, `Expected "revert", got ${error} instead`);
    if(expectedError){
      assert(error.message.includes(expectedError), "Revert found but was not: " + expectedError);
    }
  }
};
