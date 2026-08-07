import re

#Takes the hexcodes from a field and assigns it to be its color
#Must have the non-custom automatic palette already assigned

file_location = "{{Tableau Workbook .twb File Location}}"
field_name = "{{Color Field Name}}"
dashboard = []
encoding_section = False
current_color = ""
current_value = ""

with open(file_location, "r") as preferences:
    for line in preferences.readlines():
        #If in the correct color encoding section
        if encoding_section:
            if line.strip().startswith("<map"):
                #Store the format of the color mapping element
                current_value = line
            elif line.strip() == '</map>':
                #Assign the correct color and add back to the dashboard
                dashboard.append(current_value.split("'")[0] + "'#" + current_color.split("&quot;")[1] + "'" + current_value.split("'")[2])
                dashboard.append(current_color)
                dashboard.append(line)
            else:
                #Store the hexcode name
                current_color = line
        else:
            #Otherwise add the line back into the dashboard
            dashboard.append(line)

    #Check if in the encoding section based on the element and the attribute describing the hexcode field
        if re.search("<encoding.*field='[.*" + field_name + ".*]'.*>", line.strip()) is not None:
            encoding_section = True
        #If out of the encoding, stop checking for the color
        elif encoding_section and line.strip() == "</encoding>":
            encoding_section = False
            dashboard.append(line)

#Overwrite dashboard with new color encoding
with open(file_location, "w") as new_dashboard:
    new_dashboard.writelines(dashboard)