#!/usr/bin/env python
from psychopy import core, visual, event, gui, logging, sound
import numpy as np
import random
import psychopy.info

# CHOOSE YOUR monitor
# =======================
screen_to_show=1;  # 0 for this monitor, 1 for other monitor
fullScreen=False # set to true during experiments

# INITIALIZE PARAMETERS                                 TOTAL TIME = (20*5)+(40*5)+10+10=320s / 2.0 = 160 TRs (+ 4 extra??)
#===========================
numTrials=1                                              #Number of trials of stimulation+rest blocks
bufferBeginDur=0                                        #Duration of additional fixation period immediately after scan starts
bufferEndDur=0                                          #Duration of additional fixation period immediately after last rest block 
audioStimDur=921                                          #Duration of flickering checkerboard blocks
restDur=0                                               #Duration of rest blocks

movieFilename='7T_MOVIE1_CC1_v2_50.mp4';
movieSize=(1024,720);

# CREATE SCREEN
# ================
win=visual.Window([1024,720],fullscr=fullScreen,allowGUI=False,monitor='testMonitor',screen=screen_to_show,units='pix');

# STIMULI PARAMETERS
#=========================
auditory_visual=visual.MovieStim3(win,filename=movieFilename,size=movieSize);
xhr=visual.ShapeStim(win,lineColor='#000000',lineWidth=10.0,vertices=((-30,0),(30,0),(0,0),(0,30),(0,-30)),units='pix',closeShape=False,name='rest');

# ===========                INSTRUCTIONS                    ==============
# ==============================================================
Instr_Rest_T='Listen and watch the movie carefully';
Instr_Rest_S=visual.TextStim(win,text=Instr_Rest_T,height=45,units='pix',name='intro', color='black',wrapWidth=800,pos=(0,0));

Instr_Reference_T='Stay super still and fix on the crosshair';
Instr_Reference_S=visual.TextStim(win,text=Instr_Reference_T,height=45,units='pix',name='intro', color='black',wrapWidth=800,pos=(0,-100));

#Instr_Rest_Window=visual.Rect(win,width=300,height=200,pos=(0,-90),lineColor='black',lineWidth=3);
#Instr_Rest_Crosshair=visual.ShapeStim(win,lineColor='#000000',lineWidth=3.0,vertices=((-30,-90),(30,-90),(0,-90),(0,-60),(0,-120)),units='pix',closeShape=False);

# SET LOG FILE NAME
# ====================
fileDlg = gui.Dlg(title="Run Information");
fileDlg.addField('File Prefix: ');

fileDlg.show();
if gui.OK:
    Dlg_Responses=fileDlg.data;
    LogFilePrefix=Dlg_Responses[0];
    LogFileName='Logs/'+LogFilePrefix+'_ResponseLog.txt';
else: 
    LogFileName='Logs/testLog.txt';

Logger=logging.LogFile(LogFileName,34,'w');

# SETTING GENERAL CLOCK AND LOGGING
# =========================================
clock=core.Clock();
logging.setDefaultClock(clock)                                                               #use this for timing of log messages, although these shouldn't be used for experimental events
logging.console.setLevel(logging.DATA)                                            #set the console to receive nearly all messges
Logger=logging.LogFile(LogFileName,logging.DATA,'w');
win.setRecordFrameIntervals(True);                                                  #capture frame intervals
win.saveFrameIntervals(fileName=LogFileName, clear=False);          #write frame intervals to LogFileName

# (0) PRINT FIRST SET OF INSTRUCTIONS AND WAIT FOR TRIGGER
# ==================================================================
win.logOnFlip('INITIAL INSTRUCTIONS',logging.DATA);
Instr_Rest_S.draw();#Instr_Rest_Window.draw();Instr_Rest_Crosshair.draw();
win.flip();                                                                 # Plot Instructions.

# Reference scan begin
# ====================================================================
event.waitKeys(keyList=['t']); # start mannually
xhr.draw();
Instr_Reference_S.draw();
win.flip();

event.waitKeys(keyList=['t']);                                                                   # Wait for Scanner Trigger.
clock.reset();
Exp_Start_Time=clock.getTime();                                                           # Record Scanning State Time

# BEGIN EXPERIMENT
#=====================
elapsedTime=Exp_Start_Time+bufferBeginDur;

#xhr.setAutoDraw(True);                                                                          #Draw the crosshair every time the screen flips
xhr.draw();

win.flip();
win.logOnFlip('[Starting Buffer] starts FRAME TIME = {0}'.format(win.lastFrameT),logging.DATA);
win.logOnFlip('#### MOVIE FILE (1st) NAME: ' +(movieFilename) ,logging.DATA);
count=0
while clock.getTime()<elapsedTime:
    count=count+1

for i in range(numTrials):    
    win.logOnFlip('Movie start',logging.DATA);
    elapsedTime=elapsedTime+audioStimDur;
    win.flip();
    win.logOnFlip('[Stim Block {0}] starts FRAME TIME = {1}'.format(i,(win.lastFrameT)),logging.DATA);

    while clock.getTime()<elapsedTime:                                #Block of flickering checkerboard
        t=clock.getTime()
        xhr.draw();
        auditory_visual.draw()
        win.flip()
        for keys in event.getKeys(timeStamped=True):            #handle key presses each frame
            if keys[0]in ['escape','q']:
                win.close()
                core.quit()
    
    elapsedTime=elapsedTime+restDur;
    xhr.draw();
    win.flip();
    win.logOnFlip('[Rest Block {0}] starts FRAME TIME = {1}'.format(i,(win.lastFrameT)),logging.DATA);

    while clock.getTime()<elapsedTime:                                #Block of rest
        t=clock.getTime()
        for keys in event.getKeys(timeStamped=True):            #handle key presses each frame
            if keys[0]in ['escape','q']:
                win.close()
                core.quit()

elapsedTime=elapsedTime+bufferEndDur                                   #Add final buffer time of rest
win.flip();
win.logOnFlip('[Ending Buffer] starts FRAME TIME = {0}'.format(win.lastFrameT),logging.DATA);
while clock.getTime()<elapsedTime:
    count=count+1


win.flip()
win.close()
core.quit()