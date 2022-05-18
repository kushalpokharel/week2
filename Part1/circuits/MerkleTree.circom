pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";

template upperLayer(depth){
    var numElem = 1 << (depth); //calculates 2**depth ie total number of elements in tree.
    signal input ins[numElem*2];
    signal output outs[numElem];
    
    component hash[numElem];
    //for each depth we calculate the Poseidon hashes of the two elements of one level deeper elemets i.e ins
    for(var i = 0; i < numElem; i++){
        hash[i] = Poseidon(2);
        hash[i].inputs[0] <== ins[2*i];
        hash[i].inputs[1] <== ins[2*i + 1];
        outs[i] <== hash[i].out;
    }
}

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    component upperlayer[n];
    for(var i=n-1;i>=0;i--){
        upperlayer[i] = upperLayer(n); //gives the hashes of the upper layer of merkle tree
        for(var j=0;j<(1<<(n+1));j++){
            upperlayer[i].ins[j] <== (i+1==n) ? leaves[j]:upperlayer[i+1].outs[j];
        }
    }
    root <== (n>0) ? upperlayer[0].outs[0] : leaves[0];
}

template mux(){
    signal input i;
    signal input A;
    signal input B;
    signal output A_out;
    signal output B_out;

    signal tmp;
    //if the current element is on left, tmp = 0 ouptut is same as input
    //if the current element is on right, tmp = (B-A) which then switches the inputs
    tmp <== (B - A)*i;
    A_out <== tmp + A;
    B_out <== -tmp + B;
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    component multiplexor[n];
    component hasher[n];

    for(var i = 0; i < n; i++){
        multiplexor[i] = mux();
        // we take two elements (at first the given node to check whether it is included or not and another is taken from path_elements)
        multiplexor[i].A <== (i==0) ? leaf : hasher[i-1].out;
        multiplexor[i].B <== path_elements[i];
        multiplexor[i].i <== path_index[i];
        // we get the correct order of the input to be passed from the multiplexor
        hasher[i] = Poseidon(2);
        hasher[i].inputs[0] <== multiplexor[i].A_out;
        hasher[i].inputs[1] <== multiplexor[i].B_out;

    }
    //this is the root hash we calculate from the given path_elements and leaf to check whether leaf is in the merkle tree.
    //If the root matches the output we generated, the node was present in the merkle tree.
    root <== hasher[n-1].out;
}