async function main() {
  const vaultAddress = '0xd19a3a6EaDeccadbE5F288e78c8FEB6Ac556426b';
  const strategyAddress = '0xf79DBA529cf08E7Ef655b0Ce5961Bb9968F10274';

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
