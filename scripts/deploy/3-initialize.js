async function main() {
  const vaultAddress = '0x258D9405D222a5aE17011AE74A092c239018B305';
  const strategyAddress = '0x666bE8B3cAD9316490c3a57514f616f0B1BBdBD6';

  const Vault = await ethers.getContractFactory('ReaperVaultv1_3');
  const vault = Vault.attach(vaultAddress);

  const options = { gasPrice: 500000000000, gasLimit: 9000000 };
  await vault.initialize(strategyAddress, options);
  console.log('Vault initialized');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
