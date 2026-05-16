# MATLAB-radio-occultation-FYP
Uses radio occultation satellite data to characterise the ionosphere and validate the IRI
MATLAB dependencies:
Parallel computing toolbox
Mapping toolbox
Statistics and machine learning toolbox
Bioinformatics toolbox

Python 3.14 libraries:
madrigalWeb
Numpy
folium
matplotlib
branca
webbrowser
csv

To download a day, first go to the Download_pipeline.m script, enter your parameters and run it. ground will only work if you enter your GNSS API key into the download_ionex.m file.

To download IRI data, use the Madrigal model api.py script.

Most of the scripts plot what is in the name. The most important variable to know is COSMIC_data is the satellite data used.
