import {ethers} from 'hardhat'

async function main(): Promise<string> {
    const [deployer] = await ethers.getSigners()
    if (deployer === undefined) throw new Error('Deployer is undefined.')

    //["0x2D99ABD9008Dc933ff5c0CD271B88309593aB921","0x5498BB86BC934c8D34FDA08E81D444153d0D06aD","0x6EFF4835385b8D683431290356eE668193D18Efe","0xd235eD438FB2D6Bd428F5AEdF67bc8AB03bcFB96","0x09f33F64aAADf6A02956C9732b25d42DD9c2d4bC","0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3"]
    /*

    000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000060000000000000000000000002d99abd9008dc933ff5c0cd271b88309593ab9210000000000000000000000005498bb86bc934c8d34fda08e81d444153d0d06ad0000000000000000000000006eff4835385b8d683431290356ee668193d18efe000000000000000000000000d235ed438fb2d6bd428f5aedf67bc8ab03bcfb9600000000000000000000000009f33f64aaadf6a02956c9732b25d42dd9c2d4bc0000000000000000000000009ac64cc6e4415144c455bd8e4837fea55603e5c3
    */
    const MidasTokenGenerator = await ethers.getContractFactory('MidasTokenGenerator')
    const args = [
        "0x2D99ABD9008Dc933ff5c0CD271B88309593aB921",
        "0x5498BB86BC934c8D34FDA08E81D444153d0D06aD",
        "0x6EFF4835385b8D683431290356eE668193D18Efe",
        "0xd235eD438FB2D6Bd428F5AEdF67bc8AB03bcFB96",
        "0x09f33F64aAADf6A02956C9732b25d42DD9c2d4bC",
        "0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3",
    ]
    const MidasTokenGenerator_Deployed = await MidasTokenGenerator.deploy(
        args
    )
    return MidasTokenGenerator_Deployed.address;
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