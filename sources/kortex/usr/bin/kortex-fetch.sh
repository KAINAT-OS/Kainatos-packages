#!/bin/bash

mkdir -p $HOME/.config/kortex/games

lutris_json=$(lutris -l -o -j)

echo "$lutris_json" | jq -c '.[]' | while read -r game; do
    slug=$(echo "$game" | jq -r '.slug')
    id=$(echo "$game" | jq -r '.id')
    name=$(echo "$game" | jq -r '.name')
    playtime=$(echo "$game" | jq -r '.playtime // "0:00:00"')

    # Save slug,id,name,playtime in a file named after slug
    echo -e "$slug\t$id\t$name\t$playtime" > "$HOME/.config/kortex/games/$slug.txt"
done
