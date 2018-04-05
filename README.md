# LCPL Language Parser

The project contains the lexical and syntax analysis of the LCPL language

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

What things you need to install the software and how to install them:

```
sudo apt-get update
sudo apt-get install flex
sudo apt-get install bison
```
https://ccm.net/faq/30635-how-to-install-flex-and-bison-under-ubuntu

### Installing

1. Generate the lcpl-AST library:

```
$ mkdir build; cd build; cmake ..; make
```
The /include folder will contain the definitions of the AST classes.

2. Generate the parser:

```
$ make
```
The command will create the executable lcpl-parser.

## Running the tests

The project contains 2 folder for tests. 
* *Test* folder contains 3 easy source code written using the LCPL language: simple.lcpl, factorial.lcpl, hello.lcpl.
* *Tests* folder contains 3 subdirectories with input files of different complexity.

Use the command to run the parser on any of the input file:

```
$ ./lcpl-parser source_path
```
The AST representation will be written in the same location where the source file is. The output file name will have the following format: source_name.lcpl.ast.

### Check if the results are correct

The *Tests* subdirectories contain the source files as well as the reference ast representation. The file name will have the follosing format: source_name.lcpl.ast.ref.
Run the following to check if your representation is correct:

```
$ diff source_name.lcpl.ast source_nae.lcpl.ast.ref
```

To check all the tests run in the root directory:

```
$ ./compare all
```
## LCPL language syntax

### Class declararion
```
class <name> [inherits <name>]
  <members>
end;
```

Members may contain attributes of method definitions (or both).

### Attributes declaration
```
<type> <name> [ = <expression> ] ;
```

Attributes have to be declared in a **var..end;** section.
Example:
```
var Int xcar; List xcdr; end;
```

### Method declararion
```
<name> [ <args> ] [ -> <type> ] : <body> end;
```

### Example
```
class Cons
  var Int xcar; Cons xcdr; end;
  
  size -> Int:
    1 + if xcdr == null then 0; else [xcdr.size]; end;
  end;

  init Int hd, Cons tl:
    xcar = hd;
    xcdr = tl;
  end;
end;

class Main
  main:
    local Cons c; Int x; end;
    c = new Cons;
    x = 0;
    [c.init x, c];
  end;
end;
```
