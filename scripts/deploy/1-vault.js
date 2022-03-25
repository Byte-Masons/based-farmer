async function main() {
  const Vault = await ethers.getContractFactory('ReaperVaultv1_3');

  const wantAddress = '0xd4F94D0aaa640BBb72b5EEc2D85F6D114D81a88E';
  const tokenName = 'g3CRV Based Crypt';
  const tokenSymbol = 'rf-based-g3CRV-gauge';
  const depositFee = 20;
  const tvlCap = ethers.constants.MaxUint256;
  const options = { gasPrice: 300000000000, gasLimit: 9000000 };

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
