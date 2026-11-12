form Isolated asynchronous plot report
    sentence Report_path
    sentence Picture_path
endform

# Selection should be restored to what the user had (here: the "other" Sound).
writeFileLine: report_path$, numberOfSelected(), tab$, selected$("Sound")
Save as 300-dpi PNG file: picture_path$
