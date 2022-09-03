#!/usr/bin/env python3

'''      
#===============================================================================      
############################ NONLINEAR STELLA GUI ##############################
#===============================================================================
Graphical user interface, written by Hanne Thienpondt, to process and diagnose 
data generated by the gyrokinetic code stella. This is a smaller version of the 
main script of stella, that only consists of the tabs that diagnose nonlinear
simulations. Usually one only focusses on linear or nonlinear simulations, thus
the loading time of the GUI is decreased by loading only nonlinear diagnostics.
'''

# Load modules
import os, sys
import tkinter as tk
from tkinter import ttk
import matplotlib.pyplot as plt 

# Tell python where to find the personal modules and load them
sys.path.append(os.path.dirname(os.path.abspath(__file__)).split("stellapy/")[0]) 
from stellapy.utils.config.read_configurationFile import CONFIG, check_pathsToCodeAndSimulations  
from stellapy.GUI.widgets import ModifyStyling 
from stellapy.GUI.widgets.Progress import Progress
from stellapy.GUI.interface.PreferenceWindow import PreferenceWindow
from stellapy.GUI.interface.TabSelectedFiles import TabSelectedFiles  
from stellapy.GUI.interface.TabNonlinearTime import TabNonlinearTime  
from stellapy.GUI.interface.TabNonlinearSpatial import TabNonlinearSpatial   
from stellapy.utils.decorators.verbose import turn_offVerboseWrapper
from stellapy.utils.files.ensure_dir import ensure_dir
if __name__ == "__main__":
    
    #===============================================================================
    # CONFIGURATION FILE 
    #===============================================================================
    
    # Look at the paths set in the configuration file and confirm that they
    # make sense, if they are not correct the file is replaced by a default file.
    check_pathsToCodeAndSimulations()
    
    # Keep the command prompt empty of wrappers when the GUI is running.
    turn_offVerboseWrapper()
    
    # Set the default save location of the matplotlib plots.
    import matplotlib as mpl 
    mpl.rcParams["savefig.directory"] = CONFIG["PATHS"]["GUI_Figures"]
    
    #===============================================================================
    # ROOT WINDOW CREATION 
    #===============================================================================
    
    # Create the main window of the GUI/application which is called the <root>.
    title = "Stellapy: graphical environment for the gyrokinetic code stella"
    icon  = CONFIG['CODE']['Stellapy']+"GUI/images/stellarator_long.png"
    root  = tk.Tk(className="Stellapy"); root.title(title); root.geometry()
    root.iconphoto(False, tk.PhotoImage(file=icon))
    
    #===============================================================================
    # CLOSING EVENT
    #===============================================================================
    
    # Close the infinite GUI loop, the tkinter widgets and the infinite pyplot loop
    def on_closing(): 
        root.quit()                               # Exit the mainloop
        root.destroy()                            # Destroy the tkinter window
        plt.close()                               # Close the infinite plotting loop
    root.protocol("WM_DELETE_WINDOW", on_closing)
    
    #===============================================================================
    # GLOBAL VARIABLES
    #===============================================================================
    
    # The GUI groups together simulations (runs of the stella code) in a <Research>
    # object. Each <Research> holds a lists of <experiments>, while each <experiment>
    # holds a list of <simulations>, and each <simulation> consists of multiple runs
    # of the stella code, thus of multiple input files. Nonlinearly, multiple restarted
    # input files can form a single simulation, while linearly multiple modes (kx,ky)
    # can be grouped together in one simulation. Each experiment consists of a group
    # of simulations with similar input files, in order to scan over input variables.
    # Since this data is used by all widgets in the GUI, it is linked to the root.
    root.Research = type('Dummy', (object,), {'content':{}})()
    root.Research.data = {}; root.Research.experiments = []
    root.Research.input_files = []; root.input_files = []
    root.research_arguments = {}; root.Progress = Progress(root, None)
    
    # Keep track of the plotting Canvasses to allow access to the <ax> object for the 
    # Optionswindow, as well as to allow draw_idle() on it.
    root.canvasPoppedOut = [] 
    
    #===============================================================================
    # FILL THE ROOT WINDOW WITH WIDGETS AND STYLE IT TO LOOK PRETTY
    #===============================================================================
    
    # Dont flash the screen while the GUI is loading, so wait with showing the GUI.
    root.withdraw()
    
    # Style the windows and widgets.
    ModifyStyling(root, theme=CONFIG["GUI SETTINGS"]["Theme"])
    
    # Create the header for the tab, and the frames which are the tab windows.
    tab_header = ttk.Notebook(root, style='header.TNotebook')
    root.tabSelectedFiles    = ttk.Frame(tab_header) 
    root.tabNonlinearTime    = ttk.Frame(tab_header)   
    root.tabNonlinearSpatial = ttk.Frame(tab_header)     
    
    # Add the tabs to the tab header.
    tab_header.add(root.tabSelectedFiles,    text='Simulations') 
    tab_header.add(root.tabNonlinearTime,    text='Nonlinear time traces')
    tab_header.add(root.tabNonlinearSpatial, text='Nonlinear spectra and parallel mode structure') 
    tab_header.pack(expand=1, fill='both')
    
    # Make the root accessible to the tabs.
    for tab in [root.tabSelectedFiles, root.tabNonlinearTime, root.tabNonlinearSpatial]:
        tab.root = root 
    
    # Fill the tabs with widgets and plots.
    root.TabSelectedFiles  = TabSelectedFiles(root.tabSelectedFiles)    
    root.tab_NonlinearTime = TabNonlinearTime(root.tabNonlinearTime)     
    root.tab_NonlinearSpatial = TabNonlinearSpatial(root.tabNonlinearSpatial)  
    root.update_idletasks()
    
    # Since this is the nonlinear GUI, access the Nonlinear pickles
    root.TabSelectedFiles.class_research.initialdir = CONFIG['PATHS']['GUI_Pickles']+"Nonlinear"
    ensure_dir(CONFIG['PATHS']['GUI_Pickles']+"Nonlinear")
    
    # Now that all elements are initialized, show the GUI.
    root.deiconify()
    
    # Create a "dot dot dot" button which opens the preference window. Do this after
    # Plotting the GUI since the location of the button needs to be calculated based
    # on the actual size of the GUI, which isn't known until the GUI is shown.
    PreferenceWindow(root)
    root.update_idletasks()
    tab_header.select(root.tabSelectedFiles)
    
    #===============================================================================
    # INFINITE GUI LOOP
    #===============================================================================
     
    # Tell Python to run the Tkinter event loop. This method listens for events, 
    # such as button clicks or keypresses and it blocks any code that comes after 
    # it from running until the window it’s called on is closed.
    root.mainloop()







