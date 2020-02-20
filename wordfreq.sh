awk '{for (i=1; i<=NF; i++)
        words[$i]++ }
     END {for (n in words)
        print words[n], n }' |
    sort -nr -k1
