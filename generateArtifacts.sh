#!/bin/bash +x

#set -e

CHANNEL_NAME=$1
: ${CHANNEL_NAME:="mychannel"}
echo $CHANNEL_NAME

FABRIC_KEYS=$2
: ${FABRIC_KEYS:="crypto-config"}

FABRIC_ARTIFACTS=$3
: ${FABRIC_ARTIFACTS:="channel-artifacts"}

export FABRIC_ROOT=$PWD/../..
export FABRIC_CFG_PATH=$PWD
echo

OS_ARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/armv7l/g')" | awk '{print tolower($0)}')

## Using docker-compose template replace private key file names with constants
function replacePrivateKey () {
	ARCH=`uname -s | grep Darwin`
        if [ "$ARCH" == "Darwin" ]; then
                OPTS="-it"
        else
                OPTS="-i"
        fi

	cp docker-compose-e2e-template.yaml docker-compose-e2e.yaml

        CURRENT_DIR=$PWD
        cd $FABRIC_KEYS/peerOrganizations/org1.example.com/ca/
        PRIV_KEY=$(ls *_sk)
        cd $CURRENT_DIR
        sed $OPTS "s/CA1_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-e2e.yaml
        cd $FABRIC_KEYS/peerOrganizations/org2.example.com/ca/
        PRIV_KEY=$(ls *_sk)
        cd $CURRENT_DIR
        sed $OPTS "s/CA2_PRIVATE_KEY/${PRIV_KEY}/g" docker-compose-e2e.yaml
}

## Generates Org certs using cryptogen tool
function generateCerts (){
	CRYPTOGEN=./bin/cryptogen
	
	if [ -f "$CRYPTOGEN" ]; then
            echo "Using cryptogen -> $CRYPTOGEN"
        else
            echo "Building cryptogen"
            make -C $FABRIC_ROOT release-all
        fi

	echo
	echo "##########################################################"
	echo "##### Generate certificates using cryptogen tool #########"
	echo "##########################################################"
	$CRYPTOGEN generate --config=./crypto-config.yaml --output=$FABRIC_KEYS
	echo
}

## Generate orderer genesis block , channel configuration transaction and anchor peer update transactions
function generateChannelArtifacts() {
	CONFIGTXGEN=./bin/configtxgen
	
	if [ -f "$CONFIGTXGEN" ]; then
            echo "Using configtxgen -> $CONFIGTXGEN"
        else
            echo "Building configtxgen"
            make -C $FABRIC_ROOT release-all
        fi
	
	mkdir -p "$FABRIC_ARTIFACTS"
	
	echo "##########################################################"
	echo "#########  Generating Orderer Genesis block ##############"
	echo "##########################################################"
	# Note: For some unknown reason (at least for now) the block file can't be
	# named orderer.genesis.block or the orderer will fail to launch!
	$CONFIGTXGEN -profile TwoOrgsOrdererGenesis -outputBlock ./$FABRIC_ARTIFACTS/genesis.block

	echo
	echo "#################################################################"
	echo "### Generating channel configuration transaction 'channel.tx' ###"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputCreateChannelTx ./$FABRIC_ARTIFACTS/channel.tx -channelID $CHANNEL_NAME

	echo
	echo "#################################################################"
	echo "#######    Generating anchor peer update for Org1MSP   ##########"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./$FABRIC_ARTIFACTS/Org1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org1MSP

	echo
	echo "#################################################################"
	echo "#######    Generating anchor peer update for Org2MSP   ##########"
	echo "#################################################################"
	$CONFIGTXGEN -profile TwoOrgsChannel -outputAnchorPeersUpdate ./$FABRIC_ARTIFACTS/Org2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Org2MSP
	echo
}

# Modifies the nase/peer.yaml file so as the chaincode instantiation takes place on the same network as the peers
function modifyPeerBase() {
	echo "##########################################################"
        echo "#########  Modifying base/peer-base.yaml file ############"
        echo "##########################################################"


	NETWORK_HL=$(basename $PWD | tr '[:upper:]' '[:lower:]' | sed 's/[^a-zA-Z0-9]//g')
	echo $NETWORK_HL
	sed -i -e "/NETWORKMODE/c\      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE="$NETWORK_HL"_default" base/peer-base.yaml
	echo "Modified ./base/peer-base.yaml to remplace the network CORE_VM_HOSTCONFIG_NETWORKMODE to $NETWORK_HL default"
}

generateCerts
replacePrivateKey
generateChannelArtifacts
modifyPeerBase
