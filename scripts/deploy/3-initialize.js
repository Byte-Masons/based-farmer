async function main() {
  const vaultAddress = '0x21a4e2345d37a1D01F83bDA669Cc9B3F69334b6a';
  const strategyAddress = '0xE7764952590F0b321122F735c339712596E30B2C';

  const Vault = await ethers.getContractFactory('ReaperVaultv1_3');
  const vault = Vault.attach(vaultAddress);

  const options = { gasPrice: 400000000000, gasLimit: 9000000 };
  await vault.initialize(strategyAddress, options);
  console.log('Vault initialized');
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
