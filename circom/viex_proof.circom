pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

template ViexProof() {
    // private signal
    signal input sub;
    signal input aud;

    // public signal
    signal input address;
    signal input accountHash;

    // hash sub + aud + address
    component hash = Poseidon(3);
    hash.inputs[0] <== sub;
    hash.inputs[1] <== aud;
    hash.inputs[2] <== address;
 
    // create constraint equal
    component isEqual = IsEqual();
    isEqual.in[0] <== hash.out;
    isEqual.in[1] <== accountHash;

    // compare if accountHash equal hash
    isEqual.out === 1;
}

component main {public [address, accountHash]} = ViexProof();

