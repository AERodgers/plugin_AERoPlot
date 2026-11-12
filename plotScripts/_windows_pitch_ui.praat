procedure windowsPlotInitialize
        if environment$("OS") != "Windows_NT"
            exitScript: "The Windows plot UI prototype only runs on Windows. Use the original Praat action instead."
        endif
        if checkPraatVersion.major < 6 or (checkPraatVersion.major = 6 and
        ... (checkPraatVersion.minor < 4 or
        ... (checkPraatVersion.minor = 4 and checkPraatVersion.patch < 60)))
            exitScript: "The Windows plot UI prototype requires Praat 6.4.60 or newer. Use the original Praat action instead."
        endif
        windowsPlotUIExe$ = preferencesDirectory$ + "/plugin_AERoPlot/windows-ui/bin/AERoPlotWindowsUI.exe"
        if not fileReadable(windowsPlotUIExe$)
            exitScript: "The Windows plot UI has not been built. See the prototype instructions in the AERoPlot README."
        endif
        windowsPlotTempRoot$ = preferencesDirectory$ + "/plugin_AERoPlot/data/temp"
        if not folderExists(windowsPlotTempRoot$)
            createFolder: windowsPlotTempRoot$
        endif
        windowsPlotTempDir$ = windowsPlotTempRoot$ + "/plot-ui"
        if not folderExists(windowsPlotTempDir$)
            createFolder: windowsPlotTempDir$
        endif
        selectObject: sound
        windowsPlotSoundName$ = selected$("Sound")
        windowsPlotGridName$ = "-"
        if grid
            selectObject: grid
            windowsPlotGridName$ = selected$("TextGrid")
        endif
        selectObject: original_state#
endproc

procedure windowsPlotDialog
        windowsPlotTiers$ = "-"
        windowsPlotIntervalTiers$ = "-"
        windowsPlotCropTier = 0
        windowsPlotDisplayTier = 0
        if grid
            windowsPlotTiers$ = ""
            windowsPlotIntervalTiers$ = ""
            for windowsPlotTier to number_of_tiers
                if windowsPlotTier > 1
                    windowsPlotTiers$ += newline$
                endif
                if index_regex(tier_name$[windowsPlotTier], "[\t\n\r]") != 0
                    exitScript: "TextGrid tier names containing tabs or line breaks cannot be used by the Windows plot UI. Use the original Praat interface instead."
                endif
                windowsPlotTiers$ += string$(windowsPlotTier) + tab$ + tier_name$[windowsPlotTier]
                if tier_is_interval[windowsPlotTier]
                    if windowsPlotIntervalTiers$ != ""
                        windowsPlotIntervalTiers$ += ","
                    endif
                    windowsPlotIntervalTiers$ += string$(windowsPlotTier)
                endif
            endfor
            if windowsPlotTiers$ = ""
                windowsPlotTiers$ = "-"
            endif
            if windowsPlotIntervalTiers$ = ""
                windowsPlotIntervalTiers$ = "-"
            endif
            windowsPlotCropOption = 1
            if crop_tier > 1
                for windowsPlotTier to number_of_tiers
                    if tier_is_interval[windowsPlotTier]
                        windowsPlotCropOption += 1
                        if windowsPlotCropOption = crop_tier
                            windowsPlotCropTier = windowsPlotTier
                        endif
                    endif
                endfor
            endif
            if display_tier > 1
                windowsPlotDisplayTier = display_tier - 1
            endif
        endif
        if length(windowsPlotTiers$) + length(windowsPlotSoundName$) + length(windowsPlotGridName$) > 20000
            exitScript: "The selected TextGrid's tier names are too long for the Windows plot UI. Use the original Praat interface instead."
        endif
        windowsPlotTitleArg$ = image_title$
        if windowsPlotTitleArg$ = ""
            windowsPlotTitleArg$ = "__AEROPLOT_EMPTY_TITLE__"
        endif
        windowsPlotSettings$ = string$(smoothing) + tab$ +
            ... string$(paint_spectrogram) + tab$ +
            ... string$(draw_sound_waveform) + tab$ +
            ... string$(window_width) + tab$ +
            ... string$(minimum_f0) + tab$ +
            ... string$(maximum_f0) + tab$ +
            ... string$(minimum_dB) + tab$ +
            ... string$(maximum_dB) + tab$ +
            ... string$(plot_type) + tab$ +
            ... string$(f0_scale) + tab$ +
            ... string$(secondary_parameter) + tab$ +
            ... string$(font) + tab$ +
            ... string$(windowsPlotCropTier) + tab$ +
            ... string$(windowsPlotDisplayTier) + tab$ +
            ... string$(textGrid_font) + tab$ +
            ... string$(show_TextGrid_boundaries)
        windowsPlotResponse$ = runSubprocess$(
            ... windowsPlotUIExe$, "PLOT", plot_interface$,
            ... windowsPlotSoundName$, windowsPlotGridName$,
            ... windowsPlotTiers$, windowsPlotIntervalTiers$,
            ... windowsPlotTitleArg$, windowsPlotSettings$,
            ... windowsPlotTempDir$)
        windowsPlotFields$# = splitByWhitespace$#(windowsPlotResponse$)
        if size(windowsPlotFields$#) = 1
            if windowsPlotFields$#[1] = "CANCEL"
                clicked = 1
            else
                exitScript: "The Windows plot UI returned an invalid response."
            endif
        elsif size(windowsPlotFields$#) != 19
            exitScript: "The Windows plot UI returned an invalid response."
        else
            if windowsPlotFields$#[1] != "OK"
                exitScript: "The Windows plot UI returned an invalid response."
            endif
            if length(windowsPlotFields$#[2]) != 32
                exitScript: "The Windows plot UI returned an invalid title reference."
            endif
            if index_regex(windowsPlotFields$#[2], "^[a-f0-9]+$") = 0
                exitScript: "The Windows plot UI returned an invalid title reference."
            endif
            windowsPlotTitleFile$ = windowsPlotTempDir$ + "/plot-title-" + windowsPlotFields$#[2] + ".txt"
            if not fileReadable(windowsPlotTitleFile$)
                exitScript: "The Windows plot UI did not return its image title."
            endif
            image_title$ = readFile$(windowsPlotTitleFile$)
            deleteFile: windowsPlotTitleFile$
            smoothing = number(windowsPlotFields$#[3])
            paint_spectrogram = number(windowsPlotFields$#[4])
            draw_sound_waveform = number(windowsPlotFields$#[5])
            window_width = number(windowsPlotFields$#[6])
            minimum_f0 = number(windowsPlotFields$#[7])
            maximum_f0 = number(windowsPlotFields$#[8])
            minimum_F0 = minimum_f0
            maximum_F0 = maximum_f0
            minimum_dB = number(windowsPlotFields$#[9])
            maximum_dB = number(windowsPlotFields$#[10])
            plot_type = number(windowsPlotFields$#[11])
            f0_scale = number(windowsPlotFields$#[12])
            secondary_parameter = number(windowsPlotFields$#[13])
            font = number(windowsPlotFields$#[14])
            windowsPlotCropTier = number(windowsPlotFields$#[15])
            windowsPlotDisplayTier = number(windowsPlotFields$#[16])
            textGrid_font = number(windowsPlotFields$#[17])
            show_TextGrid_boundaries = number(windowsPlotFields$#[18])
            clicked = number(windowsPlotFields$#[19])
            crop_tier = 1
            windowsPlotCropOption = 1
            if windowsPlotCropTier > 0
                for windowsPlotTier to number_of_tiers
                    if tier_is_interval[windowsPlotTier]
                        windowsPlotCropOption += 1
                        if windowsPlotTier = windowsPlotCropTier
                            crop_tier = windowsPlotCropOption
                        endif
                    endif
                endfor
            endif
            display_tier = windowsPlotDisplayTier + 1
        endif
endproc
