async function main() {
  const vaultAddress = '0xcEEDEB0775e5029C1DB54A31eB1A9B3d281B19e1';
  const strategyAddress = '0xAAa8092A7C035F64cc9793BdcfDe5708d70a6458';

  const Vault = await ethers.getContractFactory('ReaperVaultv1_3');
  const vault = Vault.attach(vaultAddress);

  const options = { gasPrice: 200000000000, gasLimit: 9000000 };
  await vault.initialize(strategyAddress, options);
  console.log('Vault initialized');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
