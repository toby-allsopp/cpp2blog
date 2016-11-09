# cpp2blog

A tool to convert C++ sources to Markdown while leaving specially-marked
comments as verbatim Markdown.

Basically it wraps the whole file in `~~~c++` but drops back to raw Markdown
when it sees a line containing `/*!`.

Given input like:

~~~c++
#include <iostream>

/*!
  Here is the `main` function.
*/
int main() {
  cout << "Hello\n";
}
~~~

It will produce output like:

    ~~~c++
    #include <iostream>
    ~~~
    
    Here is the `main` function.
    
    ~~~c++
    int main() {
      cout << "Hello\n";
    }
    ~~~

## Usage

~~~
cpp2blog <FILES>...
~~~

Pass a list of source files on the command line. Markdown is emitted on standard
output.

## Building

~~~
stack setup
stack build
~~~
