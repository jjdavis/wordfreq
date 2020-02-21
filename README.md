# A Dockerized word frequency application

This application reads a text file and prints a list of words and how
frequently they occur in the file.  Docker wraps a small shell script
pipeline to do the work.

Real word frequency applications could be used in natural language
processing or cryptanalysis.  This toy application at least
illustrates some of the things a serious word frequency application
might do.

## The script

It's a shell pipeline that uses the
[AWK](https://www.gnu.org/software/gawk/) programming language to
break input lines into words and stores the words and the count for
that word in an associative array.

````
awk '{for (i=1; i<=NF; i++)
        words[$i]++ }
     END {for (n in words)
        print words[n], n }' |
    sort -nr -k1

````

The keys in the associative array are not ordered, so the script runs
the output from the `awk` command through the `sort` utility.

## The Dockerfile

The Dockerfile adds the GNU version of AWK, `gawk`, to the Alpine
Linux image and copies the script to the container.

````
FROM alpine
RUN apk --update add gawk
COPY wordfreq.sh /usr/local/bin
CMD /usr/local/bin/wordfreq.sh
````

## Testing

The application should say nothing if it has nothing to say,

````
jim@doorstop:~/wordfreq$ cat /dev/null | docker run -i bcfdocker/wordfreq
jim@doorstop:~/wordfreq$ 
````

and for monoculture input, there should be monoculture output.

````
jim@doorstop:~/wordfreq$ yes "testme" | head -1000 | docker run -i bcfdocker/wordfreq
1000 testme
````

Let's read something more ambitious: The collected works of [George
Meredith](https://en.wikipedia.org/wiki/George_Meredith), a now
obscure Victorian novelist, as collected by [Project
Gutenberg](http://www.gutenberg.org/cache/epub/4500/pg4500.txt) in a
15MB text file. The 25 most frequent words are, according to the
application,

````
jim@doorstop:~/wordfreq$ cat pg4500.txt | docker run -i bcfdocker/wordfreq 2>/dev/null | head -25
117888 the
81360 of
74886 to
63942 and
58078 
54405 a
34227 in
27938 her
27709 I
26873 was
25493 his
24686 that
24475 he
21270 for
17657 she
16670 it
16417 had
16335 with
16285 not
15933 you
15643 as
15249 is
14809 on
13960 be
13483 at
````
which looks plausible -- except for the fifth line.  58078 of what?

One guess is that it's an unprintable character that is being counted
by the application as a word.  Using the `od` command to check that

````
jim@doorstop:~/wordfreq$ cat pg4500.txt | docker run -i bcfdocker/wordfreq 2>/dev/null | head -25 | od -c
0000000   1   1   7   8   8   8       t   h   e  \n   8   1   3   6   0
0000020       o   f  \n   7   4   8   8   6       t   o  \n   6   3   9
0000040   4   2       a   n   d  \n   5   8   0   7   8      \r  \n   5
[...]
````

shows those 58078 items are indeed unprintable carriage returns
(`\r`).  The input file has DOS line endings, with runs of lines
consisting of just `\r\n` pairs that the application counts as `\r`
"words".  The application naively assumes any string of nonspace characters
is a word; a more serious word frequency application would have to
address that.

By the way the `2>/dev/null` redirection above is to avoid an ugly
error message from Docker about a broken pipe.

## Improvements

The testing points out that a naive definition of a word leads to
curious results with nonprintable characters, so a simple improvement
would be to filter out nonprintable character before running `awk`.

The current application counts lowercase 'a' and uppercase 'A' as two
distinct words.  Since there are arguments both for preserving case
and folding case, the app probably should take an option to let users
decide which they prefer.

The application also considers, say, 'said' and 'said.' as distinct
words.  The app probably should remove punctuation, though that could
also be a user option.

Ideally the application would let users specify their own definition
of a word, though it would be challenging to implement that without
requiring users to be experts in the Dark Art of regular expressions.
