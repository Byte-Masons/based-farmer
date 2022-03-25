async function main() {
  const vaultAddress = '0x590c42ab202fe170704943B1756E79B6E6140EB3';
  const strategyAddress = '0x1246cF6DAc0d3503F227832f22EDF5c3D2158D80';

  const Vault = await ethers.getContractFactory('ReaperVaultv1_3');
  const vault = Vault.attach(vaultAddress);

  const options = { gasPrice: 300000000000, gasLimit: 9000000 };
  await vault.initialize(strategyAddress, options);
  console.log('Vault initialized');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
