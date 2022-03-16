async function main() {
  const vaultAddress = '0xe5bA34cA396b62eF964eBFB45c9e90d4265e97f4';
  const strategyAddress = '0xB43dBb4fd3696c3336CE5cD05F0B41201473C1A0';

  const Vault = await ethers.getContractFactory('ReaperVaultv1_3');
  const vault = Vault.attach(vaultAddress);

  const options = { gasPrice: 600000000000, gasLimit: 9000000 };
  await vault.initialize(strategyAddress, options);
  console.log('Vault initialized');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
