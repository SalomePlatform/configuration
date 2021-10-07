ListOfSalomeTestLabelsToBeOK file contains all "salome test" labels expected to be OK for tagged released versions.
During DEV versions between tagged released versions all non passing tests should lead to a corrective action.

Each line of ListOfSalomeTestLabelsToBeOK precises a salome test label launchable using :

salome test -L <LABEL>

The format of each line :

<LABEL> <Parallelisable launch> <tests to exclude of the default list>


<Parallelisable launch> can have 2 values :

- SP : means sensible to parallelism. means that some tests in label launch several process/thread in paralle. Means that for some of them, overloaded machine test can lead to a false negative test. For these tests it's better for sustain result to launch it in sequential on a computer doing nothing else.
- PP : parallelism proof. means that all tests in label launch monothread treatments so they can be launched in parallel safely

<tests to exclude of the default list>

A comma separated list containing tests to be excluded from the tests to be OK inside the corresponding label

Examples
========

In python3 to read 

with open("ListOfSalomeTestLabelsToBeOK") as f:
    li = f.readlines()
listOfLabels = [elt.rstrip().split(" ")[0] for elt in li]
parallelismOfLabels = [elt.rstrip().split(" ")[1] for elt in li]
testsToSkipPerLabel = [elt.rstrip().split(" ")[2] for elt in li]