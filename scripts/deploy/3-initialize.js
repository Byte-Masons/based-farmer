async function main() {
  const vaultAddress = '0x9c339A3ab51205b5E2c98Cd7a4215B9B30391729';
  const strategyAddress = '0x086609816e1655AD9F7045043d6E37AC20D3EA70';

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
