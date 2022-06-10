async function main() {
  const vaultAddress = '0x73eA400B8188e59C929d1987e7DDF20691d24D86';
  const strategyAddress = '0x8C8AD36963f2fFA16578141083e949D2d1B20B27';

  const Vault = await ethers.getContractFactory('ReaperVaultv1_3');
  const vault = Vault.attach(vaultAddress);

  const options = { gasPrice: 1000000000000, gasLimit: 9000000 };
  await vault.initialize(strategyAddress, options);
  console.log('Vault initialized');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
