async function main() {
  const vaultAddress = '0x2FeF389532D7Efef5402C3CEB77b88E082F3872b';
  const strategyAddress = '0xc515392C35270A5d7bD9eeE15b55eD8a4b9F79E0';

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
