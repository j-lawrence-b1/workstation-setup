input=$1
while IFS= read -r line
do
    if (( ${#line} > 88 ))
    then
        echo "$line  # noqa E501"
    else
        echo "$line"
    fi
done < "$input"
