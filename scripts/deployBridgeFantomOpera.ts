import {ethers} from 'hardhat'

async function main() {
    const [deployer] = await ethers.getSigners()
    if (deployer === undefined) throw new Error('Deployer is undefined.')
    console.log('Deploying contracts with the account:', deployer.address)

    console.log('Account balance:', (await deployer.getBalance()).toString())

    const BridgeBsc = await ethers.getContractFactory('BridgeBsc')
    const BridgeBscDeployed = await BridgeBsc.deploy(
    )

    console.log('BridgeBscDeployed:', BridgeBscDeployed.address)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })

// 0x2D99ABD9008Dc933ff5c0CD271B88309593aB921