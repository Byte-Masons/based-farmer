async function main() {
  const Vault = await ethers.getContractFactory('ReaperVaultv1_3');

  const wantAddress = '0x00702BbDEaD24C40647f235F15971dB0867F6bdB';
  const tokenName = 'Tricrypto Based Crypt';
  const tokenSymbol = 'rf-based-crv3crypto-gauge';
  const depositFee = 0;
  const tvlCap = ethers.utils.parseEther('2000');
  const options = { gasPrice: 400000000000, gasLimit: 9000000 };

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
