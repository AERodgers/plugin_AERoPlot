form Plot viewport regression
    sentence Sound_file
    sentence Textgrid_file
    sentence Output_folder
    positive Image_width
    boolean Waveform
    boolean Display_tier
endform

grid$ = "none"
tier$ = "none"
if display_tier
    grid$ = textgrid_file$
    tier$ = "7"
endif
runScript: "cli_spectrogram.praat", sound_file$, grid$, output_folder$ + "/cli.png",
    ... 0, "300 dpi", "none", waveform, image_width, "Times", "none", tier$, "Times", 0
Save as 300-dpi PNG file: output_folder$ + "/viewport.png"
