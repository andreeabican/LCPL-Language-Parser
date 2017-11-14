#!/bin/sh

if [ "$#" -ne "1" ]
then
    echo "Usage: $0 <test_name|all>"
    echo "example: $0 basic"
    exit 1
fi

run_test() {
    ./lcpl-parser $2
    res=$?

    diff $3 $4

    if [ "$?" -eq "1" -o $res -eq "1" ]
    then
        printf "%-50s %s\n" $1 "Failed"
    else
        printf "%-50s %s\n" $1 "Passed"
    fi   
}

if [ "$1" = "all" ]
then
    echo"Intra aici"
    for i in tests/complex/*.lcpl
    do
        test_name=`basename $i .lcpl`
        test_out="tests/simple/"$test_name".lcpl.ast"
        test_ref="tests/simple/"$test_name".ast.ref"
        run_test $test_name $i $test_out $test_ref
    done
else
    echo "iNtra pe else"
    test_loc="tests/advanced/"$1".lcpl"
    test_out="tests/advanced/"$1".ast"
    test_ref="tests/advanced/"$1".ast.ref"

    run_test $1 $test_loc $test_out $test_ref
fi
