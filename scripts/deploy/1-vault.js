async function main() {
  const Vault = await ethers.getContractFactory('ReaperVaultv1_3');

  const wantAddress = '0x172BFaA8991A54ABD0b3EE3d4F8CBDab7046FF79';
  const tokenName = 'BASED-TOMB-TSWAP Based Crypt';
  const tokenSymbol = 'rf-BASED-TOMB-TSWAP';
  const depositFee = 0;
  const tvlCap = ethers.utils.parseEther('2000');
  const options = { gasPrice: 200000000000, gasLimit: 9000000 };

  const vault = await Vault.deploy(wantAddress, tokenName, tokenSymbol, depositFee, tvlCap, options);

  await vault.deployed();
  console.log('Vault deployed to:', vault.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
