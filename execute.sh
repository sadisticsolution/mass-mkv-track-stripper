#!/usr/bin/php
<?php

$config_filename = "mass-mkv-track-stripper.config";
if (!file_exists(getcwd() . "/{$config_filename}")) {
    echo "Config doesn't exist. Run inspect first\n";
    exit();
}

$config = file_get_contents(getcwd() . "/{$config_filename}");
$config_lines = explode("\n", $config);

$files = [];
$current_file = null;

foreach ($config_lines as $line) {
    if (!$line) {
        continue;
    }

    if (preg_match('/^#([0-9]+) - ([^\s]+)/', $line, $matches)) {
        // Track line
        if ($current_file === null) {
            continue;
        }

        if ($matches[2] === "subtitles") {
            $current_file["subtitles"][] = [
                "track_id" => $matches[1],
            ];
        }
    } else {
        // File line
        if ($current_file !== null) {
            $files[] = $current_file;
        }

        $current_file = [
            "filename" => $line,
            "subtitles" => [],
        ];
    }
}

if ($current_file !== null) {
    $files[] = $current_file;
}

foreach ($files as $file) {
    $arguments = [];
    $arguments[] = "-o";
    $arguments[] = escapeshellarg($file["filename"] . ".tmp");

    if (count($file["subtitles"])) {
        $arguments[] = "--subtitle-tracks";
        $arguments[] = implode(",", array_map(function ($subtitle) {
            return $subtitle["track_id"];
        }, $file["subtitles"]));
    } else {
        $arguments[] = "--no-subtitles";
    }

    $arguments[] = escapeshellarg($file["filename"]);

    passthru("mkvmerge " . implode(" ", $arguments));
    shell_exec("mv " . escapeshellarg($file["filename"] . ".tmp") . " " . escapeshellarg($file["filename"]));
}
