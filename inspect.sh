#!/usr/bin/php
<?php

$output = "";

$files = scandir(getcwd());
$files = array_filter($files, function ($file) {
    return preg_match('/\.mkv$/', $file);
});
$files = array_values($files);

foreach ($files as $file) {
    $output .= $file . "\n";
    $info = shell_exec("mkvinfo " . escapeshellarg($file));
    $info_lines = explode("\n", $info);

    $tree = [];
    $track_info = null;

    foreach ($info_lines as $line) {
        $indent = getIndentCount($line);
        $data = getLineData($line);

        $tree[$indent] = $data;
        $tree = array_slice($tree, 0, $indent + 1);

        // Check for new track
        if ($indent === 2
            && $tree[2] === "A track"
            && $tree[1] === "Segment tracks"
            && preg_match('/^Segment,/', $tree[0])) {
            // if there is a current track, output it
            if ($track_info !== null && $track_info["type"] === "subtitles") {
                $output .= outputTrack($track_info) . "\n";
            }

            $track_info = [
                "id" => null,
                "type" => null,
                "codec" => null,
                "name" => null,
            ];
            continue;
        }

        // Check for track number
        if ($indent === 3
            && preg_match('/^Track number: [0-9]+ \(track ID for mkvmerge & mkvextract: ([0-9]+)\)$/', $tree[3], $matches)
            && $tree[2] === "A track"
            && $tree[1] === "Segment tracks"
            && preg_match('/^Segment,/', $tree[0])) {
            $track_info["id"] = intval($matches[1]);
            continue;
        }

        // Check for track type
        if ($indent === 3
            && preg_match('/^Track type: (.+)$/', $tree[3], $matches)
            && $tree[2] === "A track"
            && $tree[1] === "Segment tracks"
            && preg_match('/^Segment,/', $tree[0])) {
            $track_info["type"] = $matches[1];
            continue;
        }

        // Check for track codec
        if ($indent === 3
            && preg_match('/^Codec ID: (.+)$/', $tree[3], $matches)
            && $tree[2] === "A track"
            && $tree[1] === "Segment tracks"
            && preg_match('/^Segment,/', $tree[0])) {
            $track_info["codec"] = $matches[1];
            continue;
        }

        // Check for track name
        if ($indent === 3
            && preg_match('/^Name: (.+)$/', $tree[3], $matches)
            && $tree[2] === "A track"
            && $tree[1] === "Segment tracks"
            && preg_match('/^Segment,/', $tree[0])) {
            $track_info["name"] = $matches[1];
            continue;
        }
    }

    if ($track_info !== null && $track_info["type"] === "subtitles") {
        $output .= outputTrack($track_info) . "\n";
    }
}

file_put_contents(getcwd() . "/mass-mkv-track-stripper.config", $output);
exit();

function getIndentCount(string $line) : int
{
    if (!preg_match('/^(.*)\+/', $line, $matches)) {
        return 0;
    }

    return strlen($matches[1]);
}

function getLineData(string $line) : string
{
    if (!preg_match('/^[|\s]*\+\s(.*)$/', $line, $matches)) {
        return "";
    }

    return $matches[1];
}

function outputTrack(array $track_info) : string
{
    return "#{$track_info['id']} - {$track_info['type']} - {$track_info['codec']} - {$track_info['name']}";
}
