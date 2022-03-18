import {ethers} from 'hardhat'

async function main(): Promise<string> {
    const [deployer] = await ethers.getSigners()
    if (deployer === undefined) throw new Error('Deployer is undefined.')

    const TokenVesting = await ethers.getContractFactory('TokenVesting')
    const TokenVesting_Deployed = await TokenVesting.deploy()
    return TokenVesting_Deployed.address;
}

main()
    .then((r: string) => {
        console.log(r);
        return r;
    })
    .catch(error => {
        console.error(error)
        process.exit(1)
    })