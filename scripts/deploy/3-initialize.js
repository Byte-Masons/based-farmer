async function main() {
  const vaultAddress = '0x454149160D8AE7EA63837AB9D6ED8eff69a1443a';
  const strategyAddress = '0xeCBE88f18c76c8D86cC3aFc0A1036B41E0EBa4C5';

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
