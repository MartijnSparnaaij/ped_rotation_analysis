% Graphical User Interface for annotating shoulders in video data
%
% Copyright (c) 2021 Martijn Sparnaaij
%
% Permission is hereby granted, free of charge, to any person obtaining a copy
% of this software and associated documentation files (the "Software"), to deal
% in the Software without restriction, including without limitation the rights
% to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
% copies of the Software, and to permit persons to whom the Software is
% furnished to do so, subject to the following conditions:
%
% The above copyright notice and this permission notice shall be included in all
% copies or substantial portions of the Software.
%
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
% IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
% FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
% AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
% LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
% OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
% SOFTWARE.

function varargout = shoulderGui(action, varargin)

if ~nargin
    action	= 'build';
end

if strcmpi(action, 'fcnHandle')
    varargout{:}	= eval(['@shoulderGui_' varargin{1}]);
    return
end

if nargout
    varargout		= cell(1, nargout);
    [varargout{:}]	= feval(['shoulderGui_' action], varargin{:});
else
    feval(['shoulderGui_' action], varargin{:});
end

end  % <main>
%__________________________________________________________
%% #build
%
function shoulderGui_build

figPrp = struct;
figPrp.Color            = [1 1 1] * 0.84;
figPrp.MenuBar          = 'none';
figPrp.Name             = 'Pedestrian shoulder rotation analysis tool';
figPrp.Tag              = shoulderGui_getTag;
figPrp.NumberTitle      = 'off';
figPrp.Resize           = 'on';
figPrp.Toolbar          = 'none';
figPrp.Units            = 'points';
figPrp.Visible          = 'off';
figPrp.HandleVisibility = 'off';
figPrp.CloseRequestFcn  = @shoulderGui_close;
figPrp.ResizeFcn        = @shoulderGui_resize;
fig = figure(figPrp);

appData = struct;
appData.ctrlPnl = shoulderGui_createControlPanel(fig);
[appData.imgPnl, appData.ax] = shoulderGui_createImagePanel(fig);

appData.leftShoulderPointColor = 'r';
appData.rightShoulderPointColor = 'g';
appData.activeShoulderLineColor = [1 1 1]*0.7;
appData.inactiveShoulderLineColor = [1 1 1]*0.4;
appData.inactiveShoulderPointColor = [81, 126, 198]/255;

appData.baseMarkerSize = 4;
shoulderPointPrp                    = struct;
shoulderPointPrp.Parent             = appData.ax;
shoulderPointPrp.Marker             = 'o';
shoulderPointPrp.MarkerSize         = appData.baseMarkerSize;
shoulderPointPrp.MarkerEdgeColor    = 'k';
shoulderPointPrp.ButtonDownFcn      = @shoulderGui_shoulderPointCB;

leftShoulderPointPrp = shoulderPointPrp;
leftShoulderPointPrp.MarkerFaceColor = appData.leftShoulderPointColor;
rightShoulderPointPrp = shoulderPointPrp;
rightShoulderPointPrp.MarkerFaceColor = appData.rightShoulderPointColor;

appData.leftShoulderPointPrp = leftShoulderPointPrp;
appData.rightShoulderPointPrp = rightShoulderPointPrp;

shoulderTextPrp         = struct;
shoulderTextPrp.Parent  = appData.ax;
shoulderTextPrp.FontSize = 14;
shoulderTextPrp.Color   = [175, 143, 12]/255;
shoulderTextPrp.HorizontalAlignment = 'center';
appData.shoulderTextPrp = shoulderTextPrp;

appData.selectedMarkerSize = 8;

lnPpr               = struct;
lnPpr.Parent        = appData.ax;
lnPpr.Color         = appData.activeShoulderLineColor;
lnPpr.LineWidth     = 1;
lnPpr.PickableParts = 'none';
appData.shoulderLinePrp = lnPpr;

rectanglePrps = struct;

rectanglePrps.line       = struct;
rectanglePrps.line.width = 3;
rectanglePrps.line.color = 'g';
rectanglePrps.line.lineStyle = '-';

rectanglePrps.point                         = struct;
rectanglePrps.point.marker                  = 's';
rectanglePrps.point.markerSize              = 10;
rectanglePrps.point.markerEdgeColor         = 'k';
rectanglePrps.point.markerFaceColor         = 'r';
rectanglePrps.point.markerFaceColorSelected = 'y';

appData.rectanglePrps = rectanglePrps;

appData = shoulderGui_initAppData(appData);
setAppData(fig, appData)

shoulderGui_updateImagePanel(fig)

figPos = get(fig, 'Position');
orgHeight = figPos(4);
figPos(4) = max(figPos(4), getAppData(appData.ctrlPnl, 'height'));
figPos(2) = figPos(2) - (figPos(4) - orgHeight)/2;
set(fig, 'Position', figPos);
set(fig, 'Visible', 'on')

end  % #build
%__________________________________________________________
%% #initAppData
%
function appData = shoulderGui_initAppData(appData)

appData.majorStepInd = 0;
appData.minorStepInd = 0;
appData.analysisStepInd = 0;
appData.analysisStepCount = 0;
appData.lastStepWithProcessedData = 0;
appData.videoData = '';
appData.img = '';
appData.orgImgAxLimit = [];
appData.infoText = '';
appData.stepText = '';
appData.interval = 50;
appData.rectangle = '';
appData.stepInd2dataInd = [];
appData.groups = struct('name', '', 'shoulders', '');
appData.groups(1).name = 'Group 1';
appData.groups(2).name = 'Group 2';
appData.activeShoulderPoints = gobjects(0);
appData.inactiveShoulderPoints = gobjects(0);
appData.selectedPoint = [];

appData.dataFilename = '';
appData.dataFile = '';

appData.nextIsSecondPoint = false;
appData.lastCreatedPoint = '';

end  % #initAppData
%__________________________________________________________
%% #createControlPanel
%
function hPnl = shoulderGui_createControlPanel(fig)

pnlPrp                  = struct;
pnlPrp.Parent           = fig;
pnlPrp.Units            = 'points';
pnlPrp.BackgroundColor  = [1 1 1] * 0.94;
pnlPrp.BorderType       = 'etchedout';
hPnl = uipanel(pnlPrp);

buttonSize = [80 25];
labelHeight = 20;

pnlData = struct;
pnlData.width = buttonSize(1)*2+3*5;

uiPrp0          = struct;
uiPrp0.Parent   = hPnl;
uiPrp0.Units    = 'points';
uiPrp0.FontSize = 11;

x = 5;
y = 5;

uiPrp                       = uiPrp0;
uiPrp.Style                 = 'pushbutton';
uiPrp.String                = 'Stop';
uiPrp.Enable                = 'off';
uiPrp.HorizontalAlignment   = 'left';
uiPrp.Callback              = '';
uiPrp.Position              = [x y buttonSize];
uiPrp.Callback              = @shoulderGui_stop;
pnlData.stopButton          = uicontrol(uiPrp);

uiPrp                       = uiPrp0;
uiPrp.Style                 = 'pushbutton';
uiPrp.String                = 'Go to step';
uiPrp.HorizontalAlignment   = 'left';
uiPrp.Callback              = '';
uiPrp.Enable                = 'off';
uiPrp.Position              = [x+5+buttonSize(1) y buttonSize];
uiPrp.Callback              = @shoulderGui_goTo;
pnlData.goToButton          = uicontrol(uiPrp);
y = y + buttonSize(2) + 15;

uiPrp                       = uiPrp0;
uiPrp.Style                 = 'pushbutton';
uiPrp.String                = 'Previous';
uiPrp.Enable                = 'off';
uiPrp.HorizontalAlignment   = 'left';
uiPrp.Callback              = @shoulderGui_previousStep;
uiPrp.Position              = [x y buttonSize];
pnlData.prevButton          = uicontrol(uiPrp);

uiPrp                       = uiPrp0;
uiPrp.Style                 = 'pushbutton';
uiPrp.String                = 'Next';
uiPrp.Enable                = 'off';
uiPrp.HorizontalAlignment   = 'left';
uiPrp.Callback              = @shoulderGui_nextStep;
uiPrp.Position              = [x+5+buttonSize(1) y buttonSize];
pnlData.nextButton          = uicontrol(uiPrp);
y = y + buttonSize(2) + 20;


uiPrp                       = uiPrp0;
uiPrp.Style                 = 'text';
uiPrp.HorizontalAlignment   = 'left';
uiPrp.ForegroundColor       = [1 1 1]*0.3;
uiPrp.BackgroundColor       = get(hPnl, 'BackgroundColor');

pnlData.groupBaseStr = 'Shoulders of';
pnlData.firstGroupName = 'shoulderFirstGroup';
pnlData.secondGroupName = 'shoulderSecondGroup';


stepsC = {
    %name                     label                       isSubstep
    'loadData'               'Load video'                 false
    'setDensRectangle'        'Set meas. rectangle'       false
    'setInterval'             'Set interval'              false
    'setGroupNames'           'Set group names'           false
    'performAnalysis'         'Perform analysis'          false
    pnlData.firstGroupName    'Shoulders of group ...'    true
    pnlData.secondGroupName   'Shoulders of group ...'    true
    };

steps = cell2struct(stepsC, {'name', 'label', 'isSubstep'}, 2);
stepInd2name = cell(sum(cell2mat(stepsC(:,3)) == false),2);
majorInd = 0;
minorInd = 0;

yTop = y + (numel(steps) - 1)*(labelHeight + 5);
yLoc = yTop;

for ii = 1:numel(steps)
    if steps(ii).isSubstep
        label = sprintf('   * %s', steps(ii).label);
        fontAngle = 'italic';
    else
        label = sprintf('- %s', steps(ii).label);
        fontAngle = 'normal';
    end
    uiPrp.FontAngle             = fontAngle;
    uiPrp.String                = label;
    uiPrp.Position              = [x yLoc pnlData.width - 10 labelHeight];
    pnlData.(steps(ii).name)    = uicontrol(uiPrp);
    yLoc = yLoc - (labelHeight + 5);
    if steps(ii).isSubstep
        minorInd = minorInd + 1;
        stepInd2name{majorInd,2}{end+1} = steps(ii).name;
    else
        majorInd = majorInd + 1;
        minorInd = 0;
        stepInd2name(majorInd,:) = {steps(ii).name, {}};
    end
end % for ii

y = yTop + labelHeight + 5;

uiPrp.ForegroundColor       = 'k';
uiPrp.FontSize              = 14;
uiPrp.FontWeight            = 'bold';
uiPrp.String                = 'Steps:';
uiPrp.Position              = [x y pnlData.width - 10 labelHeight];
uicontrol(uiPrp)


y = y + labelHeight + 10;

uiPrp.ForegroundColor       = [1 1 1]*0.4;
uiPrp.FontSize              = 9;
uiPrp.FontWeight            = 'normal';
uiPrp.String                = '<data filename>';
uiPrp.Position              = [x y pnlData.width - 10 labelHeight+5];
pnlData.dataFlNmLabel       = uicontrol(uiPrp);

y = y + labelHeight + 5;

uiPrp.ForegroundColor       = 'k';
uiPrp.FontSize              = 12;
uiPrp.FontWeight            = 'bold';
uiPrp.String                = 'Data filename';
uiPrp.Position              = [x y pnlData.width - 10 labelHeight];
uicontrol(uiPrp)

y = y + labelHeight + 5;

uiPrp.ForegroundColor       = [1 1 1]*0.4;
uiPrp.FontSize              = 9;
uiPrp.FontWeight            = 'normal';
uiPrp.String                = '<video filename>';
uiPrp.Position              = [x y pnlData.width - 10 labelHeight+5];
pnlData.videoFlNmLabel      = uicontrol(uiPrp);

y = y + labelHeight + 5;

uiPrp.ForegroundColor       = 'k';
uiPrp.FontSize              = 12;
uiPrp.FontWeight            = 'bold';
uiPrp.String                = 'Video filename';
uiPrp.Position              = [x y pnlData.width - 10 labelHeight];
uicontrol(uiPrp)


pnlData.stepInd2name = stepInd2name;
pnlData.height = y + labelHeight + 5;

pnlData.steps = steps;
setAppData(hPnl, pnlData)

end  % #createControlPanel
%__________________________________________________________
%% #createImagePanel
%
function [hPnl, ax] = shoulderGui_createImagePanel(fig)

pnlPrp                  = struct;
pnlPrp.Parent           = fig;
pnlPrp.Units            = 'points';
pnlPrp.BackgroundColor  = [1 1 1] * 0.94;
pnlPrp.BorderType       = 'etchedout';
hPnl = uipanel(pnlPrp);

axPrp           = struct;
axPrp.Parent    = hPnl;
axPrp.FontSize  = 10;
axPrp.Box       = 'on';
ax = axes(axPrp);

xlabel(ax, 'X [pixels]')
ylabel(ax, 'Y [pixels]')

pnlData.overlay = '';

setAppData(hPnl, pnlData)

end  % #createImagePanel
%__________________________________________________________
%% #getTag
%
function tag = shoulderGui_getTag

tag = 'shoulderGui';

end  % #getTag
%__________________________________________________________
%% #close
%
function shoulderGui_close(h, ~)

fig = hfigure(h);

title = 'Close?';
question = 'Do you want to close the Shoulder gui window?';

answer = questdlg(question, title, 'Yes', 'No', 'No');
if strcmpi(answer, 'yes')
    appData = getAppData(fig);
    if ~isempty(appData.dataFilename)
        shoulderGui_saveData2file(appData, 'all')
    end
    delete(fig)
end

end  % #close
%__________________________________________________________
%% #resize
%
function shoulderGui_resize(h, ~)

fig = hfigure(h);
appData = getAppData(fig);
if strcmpi(get(fig, 'Visible'), 'off')
    return
end

% =========== get data ===========
figPos = get(fig, 'Position');

% =========== control panel ===========
ctrlPnlData = getAppData(appData.ctrlPnl);
ctrlPnlPos = [0, figPos(4) - ctrlPnlData.height, ctrlPnlData.width, ctrlPnlData.height];

% =========== image panel ===========

imgPnlPos = [ctrlPnlPos(1) + ctrlPnlPos(3), 0,...
    figPos(3) - ctrlPnlPos(1)  - ctrlPnlPos(3), figPos(4)];

imgPnlData = getAppData(appData.imgPnl);
if ~isempty(imgPnlData.overlay)
    overlayPos = get(imgPnlData.overlay, 'pos');
    x = max(0, (imgPnlPos(3) - overlayPos(3))/2);
    y = max(0, (imgPnlPos(4) - overlayPos(4))/2);
    overlayPos(1:2) = [x, y];
    set(imgPnlData.overlay, 'Position', overlayPos);
end

% =========== set data ===========
set(appData.ctrlPnl, 'Position', ctrlPnlPos);
set(appData.imgPnl, 'Position', imgPnlPos);

end  % #resize
%__________________________________________________________
%% #nextStep
%
function shoulderGui_nextStep(h, ~)

fig = hfigure(h);
appData = getAppData(fig);

switch appData.majorStepInd
    case 0 % Start
        appData.majorStepInd = appData.majorStepInd + 1;
    case 1 % Load video
        succes = shoulderGui_videoLoaded(fig);
        if succes
            [saveFileSucces, appData] = shoulderGui_initSaveFile(appData);
            if ~saveFileSucces
                return
            end
            shoulderGui_saveData2file(appData, 'videoData');
            appData.majorStepInd = appData.majorStepInd + 1;
            appData.orgImgAxLimit = [get(appData.ax, 'XLim'), get(appData.ax, 'YLim')];
            set(appData.img, 'ButtonDownFcn', @shoulderGui_rectangleButtonDownCB)
            pnlData = getAppData(getAppData(fig, 'ctrlPnl'));
            set(pnlData.stopButton, 'enable', 'on')
        else
            msgbox('No video loaded yet!', 'No video','modal')
        end
    case 2 % Set density rectangle
        if isempty(appData.rectangle)
            msgbox('Rectangle not yet defined!', 'Cannot continue')
            return
        end
        shoulderGui_saveData2file(appData, 'rectangle');
        shoulderGui_rectangleCornersSwitch(appData, false)
        shoulderGui_zoomAxes(appData);
        appData.majorStepInd = appData.majorStepInd + 1;
    case 3 % Set interval
        [ok, interval] = shoulderGui_getInterval(appData);
        if ~ok
            return
        end
        appData.majorStepInd = appData.majorStepInd + 1;
        if interval ~= appData.interval || isempty(appData.stepInd2dataInd)
            appData.interval = interval;
            appData = shoulderGui_calcIntervalCount(appData);
            appData = shoulderGui_setAxTitle(appData, 1);
            shoulderGui_saveData2file(appData, 'interval');
        else
            appData = shoulderGui_setAxTitle(appData, 1);
        end
    case 4 % Set group names
        [ok, appData] = shoulderGui_checkGroupNames(appData);
        if ok
            appData.majorStepInd = appData.majorStepInd + 1;
            appData.analysisStepInd = 1;
            appData.minorStepInd = 1;
            shoulderGui_updateGroupNamesInCtrlPnl(fig, appData.groups)
            if isempty(appData.dataFilename)
                [succes, appData.dataPd, appData.dataFilename] = shoulderGui_chooseSaveFilename();
                if ~succes
                    msgbox('No save file selected yet!', 'No save file','modal')
                end
            end
            shoulderGui_saveData2file(appData, 'groups');
            set(appData.img, 'ButtonDownFcn', @shoulderGui_addShoulderPoint)
            appData = shoulderGui_setPointsBasedOnData(appData);
            set(getAppData(appData.ctrlPnl, 'goToButton'), 'enable', 'on')
        end
    case 5 % perform analysis
        appData = shoulderGui_saveShoulderData(appData, appData.minorStepInd, appData.analysisStepInd);
        if appData.minorStepInd == 1
            appData.minorStepInd = 2;
        else
            appData.minorStepInd = 1;
            appData.analysisStepInd = appData.analysisStepInd + 1;
            if appData.analysisStepInd > appData.analysisStepCount
                shoulderGui_stop(fig, '')
                return
            end
            shoulderGui_saveData2file(appData, 'groups');
            % Show next frame
            appData = shoulderGui_setAxImage(appData, appData.analysisStepInd);
            % Update step text
            % set active and inactive points based on data
            appData = shoulderGui_setPointsBasedOnData(appData);
        end
end % switch

setAppData(fig, appData)
shoulderGui_updateImagePanel(fig)
shoulderGui_updateSteps(fig)

end  % #nextStep
%__________________________________________________________
%% #previousStep
%
function shoulderGui_previousStep(h, ~)

fig = hfigure(h);

appData = getAppData(fig);

if appData.majorStepInd == 3
    shoulderGui_rectangleCornersSwitch(appData, true)
    shoulderGui_resetAxZoom(appData)
    set(fig, 'WindowKeyPressFcn', @shoulderGui_rectangleKeyPressAddSub)
end

if appData.majorStepInd == 4
    shoulderGui_saveData2file(appData, 'groups');
end

if appData.majorStepInd == 5
    appData = shoulderGui_saveShoulderData(appData, appData.minorStepInd, appData.analysisStepInd);
    if appData.minorStepInd == 1
        appData.analysisStepInd = appData.analysisStepInd - 1;
        appData = shoulderGui_clearPoints(appData);
        if appData.analysisStepInd == 0
            appData.minorStepInd = 0;
            appData.majorStepInd = appData.majorStepInd - 1;
            set(getAppData(appData.ctrlPnl, 'goToButton'), 'enable', 'off')
            set(appData.img, 'ButtonDownFcn', '')
        else
            appData.minorStepInd = 2;
            % Set previous frame
            appData = shoulderGui_setAxImage(appData, appData.analysisStepInd);
            % Add points of current step and set group 2 to active
            appData = shoulderGui_setPointsBasedOnData(appData);
        end
    elseif appData.minorStepInd == 2
        appData.minorStepInd = 1;
        % Add points of current step
        appData = shoulderGui_setPointsBasedOnData(appData);
    end
else
    appData.majorStepInd = appData.majorStepInd - 1;
end

setAppData(fig, appData)
shoulderGui_updateImagePanel(fig)
shoulderGui_updateSteps(fig)

end  % #previousStep
%__________________________________________________________
%% #stop
%
function shoulderGui_stop(h, ~)

answer = questdlg('Are you sure the analysis is finished', 'Stop', 'Yes', 'No', 'No');
if ~strcmpi(answer, 'yes')
    return
end

fig = hfigure(h);
appData = getAppData(fig);
shoulderGui_saveData2file(appData, 'all')
appData = shoulderGui_initAppData(appData);
cla(appData.ax)
delete(appData.axTitle)
appData.axTitle = '';
setAppData(fig, appData)

set(getAppData(appData.ctrlPnl, 'goToButton'), 'enable', 'off')
set(getAppData(appData.ctrlPnl, 'stopButton'), 'enable', 'off')

shoulderGui_updateImagePanel(fig)
shoulderGui_updateSteps(fig)

end  % #stop
%__________________________________________________________
%% #goTo
%
function shoulderGui_goTo(h, ~)

fig = hfigure(h);
lastStepWithProcessedData = getAppData(fig, 'lastStepWithProcessedData');
analysisStepCount = getAppData(fig, 'analysisStepCount');
curStepInd = getAppData(fig, 'analysisStepInd');
answer = inputdlg({sprintf('Go to step (%d):', lastStepWithProcessedData)},'Go to step', [1, 20], {num2str(curStepInd)});

if isempty(answer)
    return
end

newStepInd = str2num(answer{1}); %#ok<ST2NM>
if numel(newStepInd) ~= 1
    hDlg = errordlg('The value must be numeric', 'Invalid value');
    waitfor(hDlg)
    shoulderGui_goTo(fig, {})
    return
end

if floor(newStepInd) ~= newStepInd
    hDlg = errordlg('The value must be an integer', 'Invalid value');
    waitfor(hDlg)
    shoulderGui_goTo(fig, {})
    return
end
if newStepInd <= 0 || newStepInd > analysisStepCount
    hDlg = errordlg(sprintf('The value must be larger than 0 and smaller than %u', analysisStepCount), 'Invalid value');
    waitfor(hDlg)
    shoulderGui_goTo(fig, {})
    return
end

if newStepInd == curStepInd
    return
end

appData = getAppData(fig);
if appData.minorStepInd == 1
    appData = shoulderGui_saveShoulderData(appData, appData.minorStepInd, appData.analysisStepInd);
end

appData.minorStepInd = 2;
appData = shoulderGui_saveShoulderData(appData, appData.minorStepInd, appData.analysisStepInd);

shoulderGui_saveData2file(appData, 'groups');

appData.analysisStepInd = newStepInd;
appData.minorStepInd = 1;

appData = shoulderGui_setAxImage(appData, appData.analysisStepInd);
appData = shoulderGui_setPointsBasedOnData(appData);

setAppData(fig, appData)

shoulderGui_updateImagePanel(fig)
shoulderGui_updateSteps(fig)

end  % #goTo
%__________________________________________________________
%% #updateSteps
%
function shoulderGui_updateSteps(fig)

majorStepInd = getAppData(fig, 'majorStepInd');
minorStepInd = getAppData(fig, 'minorStepInd');
pnlData = getAppData(getAppData(fig, 'ctrlPnl'));

for ii = 1:numel(pnlData.steps)
    set(pnlData.(pnlData.steps(ii).name), 'FontWeight', 'normal')
end % for ii

set(pnlData.nextButton, 'enable', 'on')
set(pnlData.prevButton, 'enable', 'on')
if majorStepInd <= 2
    set(pnlData.prevButton, 'enable', 'off')
end

if majorStepInd > 0
    mainUiCtrl = pnlData.(pnlData.stepInd2name{majorStepInd,1});
    set(mainUiCtrl, 'FontWeight', 'bold')
end

if minorStepInd > 0
    minorUiCtrl = pnlData.(pnlData.stepInd2name{majorStepInd,2}{minorStepInd});
    set(minorUiCtrl, 'FontWeight', 'bold')
end

end  % #updateSteps
%__________________________________________________________
%% #updateImagePanel
%
function shoulderGui_updateImagePanel(fig)

appData = getAppData(fig);

pnlData = getAppData(appData.imgPnl);

% Remove all current ui controls
if ~isempty(pnlData.overlay)
    delete(pnlData.overlay)
    pnlData.overlay = '';
end

% Remove callbacks
pnlPrp                  = struct;
pnlPrp.Parent           = appData.imgPnl;
pnlPrp.Units            = 'points';
pnlPrp.BackgroundColor  = [1 1 1] * 0.40;
pnlPrp.BorderType       = 'beveledout';

switch appData.majorStepInd
    case 0 % Start new analysis or continue from previous analysis
        pnlPrp.Position = [0,0,134,78];
        pnlData.overlay = uipanel(pnlPrp);
        uiPrp           = struct;
        uiPrp.Parent    = pnlData.overlay;
        uiPrp.Units     = 'Points';
        uiPrp.Style     = 'PushButton';
        uiPrp.FontSize  = 11;

        uiPrp.String    = 'Start new analysis';
        uiPrp.Position  = [9, 43, 115, 25];
        uiPrp.Callback  = @shoulderGui_nextStep;
        uicontrol(uiPrp)

        uiPrp.String    = 'Continue analysis';
        uiPrp.Position  = [9, 9, 115, 25];
        uiPrp.Callback  = @shoulderGui_loadMat;
        uicontrol(uiPrp)
    case 1 % Load video
        pnlPrp.Position = [0,0,100,45];
        pnlData.overlay = uipanel(pnlPrp);
        uiPrp           = struct;
        uiPrp.Parent    = pnlData.overlay;
        uiPrp.Units     = 'Points';
        uiPrp.Style     = 'PushButton';
        uiPrp.String    = 'Load video';
        uiPrp.FontSize  = 11;
        uiPrp.Position  = [9, 9, 85, 25];
        uiPrp.Callback  = @shoulderGui_loadVideoCB;
        uicontrol(uiPrp)
    case 2 % Set measurement rectangle
        pnlPrp.Position = [0,0,100,45];
        pnlData.overlay = uipanel(pnlPrp);
        uiPrp           = struct;
        uiPrp.Parent    = pnlData.overlay;
        uiPrp.Units     = 'Points';
        uiPrp.Style     = 'ToggleButton';
        uiPrp.String    = 'Zoom';
        uiPrp.FontSize  = 11;
        uiPrp.Position  = [9, 9, 85, 25];
        uiPrp.Callback  = @shoulderGui_zoomSwitch;
        uicontrol(uiPrp)

    case 3 % Set interval
        pnlData.interval = getAppData(fig, 'interval');
        pnlPrp.Position = [0,0,140,40];
        pnlData.overlay = uipanel(pnlPrp);
        uiPrp                   = struct;
        uiPrp.Parent            = pnlData.overlay;
        uiPrp.Units             = 'Points';
        uiPrp.BackgroundColor   = get(pnlData.overlay, 'BackgroundColor');
        uiPrp.ForegroundColor   = 'w';
        uiPrp.Style             = 'text';
        uiPrp.String            = 'Interval [frames]:';
        uiPrp.FontSize          = 11;
        uiPrp.FontWeight        = 'bold';
        uiPrp.Position          = [9, 6, 95, 20];
        uicontrol(uiPrp)

        uiPrp.Style             = 'edit';
        uiPrp.BackgroundColor   = 'w';
        uiPrp.ForegroundColor   = 'k';
        uiPrp.String            = num2str(appData.interval);
        uiPrp.FontWeight        = 'normal';
        uiPrp.Position          = [104, 9, 30, 20];
        pnlData.intervalEdit    = uicontrol(uiPrp);
    case 4
        pnlPrp.Position = [0,0,140,67];
        pnlData.overlay = uipanel(pnlPrp);

        uiPrp                   = struct;
        uiPrp.Parent            = pnlData.overlay;
        uiPrp.Units             = 'Points';
        uiPrp.BackgroundColor   = get(pnlData.overlay, 'BackgroundColor');
        uiPrp.ForegroundColor   = 'w';
        uiPrp.Style             = 'text';
        uiPrp.FontSize          = 11;
        uiPrp.FontWeight        = 'bold';

        uiPrp.String            = 'Group 2:';
        uiPrp.Position          = [9, 6, 50, 20];
        uicontrol(uiPrp)
        uiPrp.String            = 'Group 1:';
        uiPrp.Position          = [9, 33, 50, 20];
        uicontrol(uiPrp)

        uiPrp.Style             = 'edit';
        uiPrp.BackgroundColor   = 'w';
        uiPrp.ForegroundColor   = 'k';
        uiPrp.FontWeight        = 'normal';

        uiPrp.String            = appData.groups(2).name;
        uiPrp.Position          = [59, 9, 75, 20];
        pnlData.group2Edit      = uicontrol(uiPrp);
        uiPrp.String            = appData.groups(1).name;
        uiPrp.Position          = [59, 36 75, 20];
        pnlData.group1Edit      = uicontrol(uiPrp);
end

setAppData(appData.imgPnl, pnlData)
shoulderGui_resize(fig, '')

end  % #updateImagePanel
%__________________________________________________________
%% #loadVideoCB
%
function videoData = shoulderGui_loadVideoCB(h, ~)

dataPd = fullfile(cd, 'data', 'input');
if ~isfolder(dataPd)
    dataPd = cd;
end

[file, path] = uigetfile({'*.mp4'}, 'Select movie', dataPd);
if file == 0
    return
end

fig = hfigure(h);
videoData = shoulderGui_loadVideo(fig, path, file);

setAppData(fig, videoData, 'videoData')
shoulderGui_initAxImage(fig)

end % #loadVideoCB
%__________________________________________________________
%% #loadVideo
%
function videoData = shoulderGui_loadVideo(fig, path, file)

videoData = struct;
videoData.flNm = fullfile(path, file);
videoData.file = file;

try
    videoData.vidObj = VideoReader(videoData.flNm);
catch
    errordlg('Error while loading video', 'Error')
    return
end

videoFlNmLabel = getAppData(getAppData(fig, 'ctrlPnl'), 'videoFlNmLabel');
set(videoFlNmLabel, 'String', file)

end  % #loadVideo
%__________________________________________________________
%% #loadMat
%
function shoulderGui_loadMat(h, ~)

dataPd = fullfile(cd, 'data');
if ~isfolder(dataPd)
    dataPd = cd;
end

[file, path] = uigetfile({'*.mat'}, 'Select data file', dataPd);
if file == 0
    return
end

dataFlNm = fullfile(path, file);
[pd, fl, ~] = fileparts(dataFlNm);
backupFlNm = dataFlNm;
backupInd = 1;
while isfile(backupFlNm)
    backupFlNm = fullfile(pd, sprintf('%s_%02d.bak', fl, backupInd));
    backupInd = backupInd + 1;
end % while
copyfile(dataFlNm, backupFlNm, 'f');
data = load(dataFlNm);

fig = hfigure(h);
appData = getAppData(fig);

videoPdParts = data.video.pdParts;
if any(strncmp(videoPdParts, '.', 1))
    if strcmp(videoPdParts{1}, '.')
        videoPd = fullfile(pd, videoPdParts{2:end});
    else
        stepsUp = sum(strcmp(videoPdParts, '..'));
        dataPdParts = strsplit(pd, filesep);
        if isempty(dataPdParts{end})
            dataPdParts(end) = [];
        end
        videoPd = fullfile(dataPdParts{1:end-stepsUp}, videoPdParts{stepsUp+1:end});
    end
else
    videoPd = fullfile(videoPdParts{:});
end

videoData = shoulderGui_loadVideo(fig, videoPd, data.video.file);
appData.videoData = videoData;
appData.interval = data.interval;

setAppData(fig, appData)
shoulderGui_initAxImage(fig)
appData = getAppData(fig);
appData.orgImgAxLimit = [get(appData.ax, 'XLim'), get(appData.ax, 'YLim')];
appData.analysisStepCount = data.analysisStepCount;
appData.stepInd2dataInd = 1:data.analysisStepCount;
setAppData(fig, appData)

shoulderGui_addRectangleFromData(fig, data.rectangle)
appData = getAppData(fig);
shoulderGui_rectangleCornersSwitch(appData, false)

for ii = 1:numel(data.groups)
    appData.groups(ii) = data.groups(ii);
    for jj = 1:size(appData.groups(ii).shoulders, 1)
        orgPoints = appData.groups(ii).shoulders{jj,3};
        if isempty(orgPoints) || size(orgPoints, 2) == 5
            continue
        end
        pointData = nan(size(orgPoints,1),5);
        pointData(:,1:4) = orgPoints;
        appData.groups(ii).shoulders{jj,3} = pointData;
    end % for jj
end % for ii
appData = shoulderGui_checkShoulders(appData);

if isfield(data, 'lastStepWithProcessedData')
    appData.lastStepWithProcessedData = data.lastStepWithProcessedData;
end

appData.majorStepInd = 4;
appData = shoulderGui_setAxImage(appData, 1);
appData.dataFilename = dataFlNm;
appData.dataPd = dataPd;

shoulderGui_zoomAxes(appData);
[~, appData] = shoulderGui_initSaveFile(appData);
setAppData(fig, appData)

shoulderGui_updateImagePanel(fig)
shoulderGui_nextStep(fig, {})

end  % #loadMat
%__________________________________________________________
%% #videoLoaded
%
function succes = shoulderGui_videoLoaded(fig)

succes = ~isempty(getAppData(fig, 'videoData'));

end  % #videoLoaded
%__________________________________________________________
%% #getInterval
%
function [ok, interval] = shoulderGui_getInterval(appData)

h = getAppData(appData.imgPnl, 'intervalEdit');
interval = str2num(get(h, 'String')); %#ok<ST2NM>
ok = false;
if numel(interval) ~= 1
    errordlg('The value must be numeric', 'Invalid value')
    set(h, 'String', num2str(appData.interval))
    return
end

if floor(interval) ~= interval
    errordlg('The value must be an integer', 'Invalid value')
    set(h, 'String', num2str(appData.interval))
    return
end
if interval <= 0
    errordlg('The value must be larger than 0', 'Invalid value')
    set(h, 'String', num2str(appData.interval))
    return
end

ok = true;

end  % #getInterval
%__________________________________________________________
%% #initAxImage
%
function shoulderGui_initAxImage(fig)

imgPnl = getAppData(fig, 'imgPnl');
ax = getAppData(fig, 'ax');

txtPrp                      = struct;
txtPrp.Parent               = ax;
txtPrp.Color                = 'w';
txtPrp.FontSize             = 11;
txtPrp.HorizontalAlignment  = 'right';
txtPrp.VerticalAlignment    = 'top';
txtPrp.Units                = 'normalized';
txtPrp.Position             = [1,1,0];

setAppData(imgPnl, txtPrp, 'infoTextPrp');

appData = getAppData(fig);
appData = shoulderGui_setAxImage(appData, 1);
xlabel(appData.ax, 'X')
ylabel(appData.ax, 'Y')
appData.axTitle = title(appData.ax, 'Step # of #');
setAppData(fig, appData)

end  % #initAxImage
%__________________________________________________________
%% #setAxImage
%
function appData = shoulderGui_setAxImage(appData, stepInd)

pnlData = getAppData(appData.imgPnl);
videoData = appData.videoData;
ax = appData.ax;

frameNr = (stepInd - 1)*appData.interval + 1;
time = (frameNr - 1)*(1/videoData.vidObj.FrameRate);

videoData.vidObj.CurrentTime = time;
frame = readFrame(videoData.vidObj);

if isempty(appData.img)
    appData.img = imagesc(ax, frame);
else
    set(appData.img, 'CData', frame)
end

if ~isempty(appData.rectangle)
    for ii = 1:numel(appData.rectangle.lines)
        uistack(appData.rectangle.lines(ii), 'top')
    end
end

min = floor(time/60);
sec = floor(time - min*60);
milisec = round((time - min*60 - sec)*1000);

infoStr = sprintf('Time: %02u:%02u:%04u, Frame: %04u, Frame rate: %.2f [frame/s]',...
    min, sec, milisec, frameNr, videoData.vidObj.FrameRate);

if ~isempty(appData.infoText)
    set(appData.infoText, 'String', infoStr)
else
    txtPrp = pnlData.infoTextPrp;
    txtPrp.String = infoStr;
    appData.infoText = text(txtPrp);
end

appData = shoulderGui_setAxTitle(appData, stepInd);
set(ax, 'DataAspectRatioMode', 'manual', 'DataAspectRatio', [1, 1 1]);

end  % #setAxImage
%__________________________________________________________
%% #setAxTitle
%
function appData = shoulderGui_setAxTitle(appData, stepInd)

if appData.analysisStepCount > 0
    set(appData.axTitle, 'String', sprintf('Step %u of %u', stepInd, appData.analysisStepCount))
end

end  % #setAxTitle
%__________________________________________________________
%% #calcIntervalCount
%
function appData = shoulderGui_calcIntervalCount(appData)

frameCount = appData.videoData.vidObj.Duration*appData.videoData.vidObj.FrameRate;
appData.analysisStepCount = floor(frameCount/appData.interval);

if ~isempty(appData.groups(1).shoulders)
    for ii = 1:numel(appData.groups)
        orgShoulderData = appData.groups(ii).shoulders;
        orgShoulderData(cellfun(@isempty, orgShoulderData(:,1)),1) = {NaN};
        orgFrameNrs = cell2mat(orgShoulderData(:,1));
        newFrameNrs = transpose(1:appData.interval:appData.interval*appData.analysisStepCount);
        frameNrs = union(newFrameNrs, orgFrameNrs);
        [~, orgDataInd ,~] = intersect(frameNrs, orgFrameNrs);
        [~, newDataInd ,~] = intersect(frameNrs, newFrameNrs);
        appData.groups(ii).shoulders = cell(numel(frameNrs), 3);
        for jj = 1:numel(orgDataInd)
            appData.groups(ii).shoulders(orgDataInd(jj),:) = orgShoulderData(jj,:);
        end % for jj
        appData.stepInd2dataInd = newDataInd;
    end % for ii
else
    appData.stepInd2dataInd = 1:appData.analysisStepCount;
    for ii = 1:numel(appData.groups)
        appData.groups(ii).shoulders = cell(appData.analysisStepCount, 3);
    end % for ii
end

end  % #calcIntervalCount
%__________________________________________________________
%% #rectangleButtonDownCB
%
function shoulderGui_rectangleButtonDownCB(h, evd)

fig = hfigure(h);

rectangle = struct;
rectangle.activePoint = '';
setAppData(fig, rectangle, 'rectangle');

% draw rectangle
shoulderGui_drawRectangle(fig, evd.IntersectionPoint(1),...
    evd.IntersectionPoint(2), evd.IntersectionPoint(1),...
    evd.IntersectionPoint(2), 0);

appData = getAppData(fig);
set(appData.rectangle.points(2), 'MarkerFaceColor',...
    appData.rectanglePrps.point.markerFaceColorSelected);

appData.rectangle.activePoint = appData.rectangle.points(2);

setAppData(fig, appData)
% Add windowButtonMotionFcn
% Add windowButtonUpFcn
% Remove windowButtonDownFcn
set(appData.img, 'ButtonDownFcn', '')

set(fig, 'WindowButtonMotionFcn', {@shoulderGui_rectangleButtonMotionCB, fig})
set(fig, 'WindowButtonUpFcn', {@shoulderGui_rectangleButtonUpCB, fig})
drawnow

end  % #rectangleCB
%__________________________________________________________
%% #rectangleButtonMotionCB
%
function shoulderGui_rectangleButtonMotionCB(~, evd, fig)

% update regtangle

rectangle = getAppData(fig, 'rectangle');

set(rectangle.activePoint, 'XData', evd.IntersectionPoint(1),...
    'YData', evd.IntersectionPoint(2))

if rectangle.activePoint == rectangle.points(2)
    x0 = get(rectangle.points(1), 'XData');
    y0 = get(rectangle.points(1), 'YData');
    x1 = evd.IntersectionPoint(1);
    y1 = evd.IntersectionPoint(2);
else
    x1 = get(rectangle.points(2), 'XData');
    y1 = get(rectangle.points(2), 'YData');
    x0 = evd.IntersectionPoint(1);
    y0 = evd.IntersectionPoint(2);
end

if rectangle.angle ~= 0
    angle = -rectangle.angle;
    R = [cosd(angle), -sind(angle);sind(angle), cosd(angle)];
    virtualCoords = R*[x1-x0; y1-y0];
    x1 = virtualCoords(1) + x0;
    y1 = virtualCoords(2) + y0;
end

[lineCoords, extent, ~, ~] = shoulderGui_getRectangleLineCoords(x0, y0, x1, y1, rectangle.angle);
for ii = 1:numel(lineCoords)
    set(rectangle.lines(ii), 'XData', lineCoords(ii).x, 'YData', lineCoords(ii).y)
end

setAppData(fig, extent, 'rectangle.extent')

drawnow

end  % #rectangleButtonMotionCB
%__________________________________________________________
%% #rectangleButtonUpCB
%
function shoulderGui_rectangleButtonUpCB(~, ~, fig)

set(fig, 'WindowButtonMotionFcn', '')
set(fig, 'WindowButtonUpFcn', '')

try
    appData = getAppData(fig);
    set(appData.rectangle.activePoint, 'MarkerFaceColor', ...
        appData.rectanglePrps.point.markerFaceColor)
    appData.rectangle.activePoint = '';

    setAppData(fig, appData)

    set(appData.rectangle.points(1), 'ButtonDownFcn', @shoulderGui_rectangleCornerCB)
    set(appData.rectangle.points(2), 'ButtonDownFcn', @shoulderGui_rectangleCornerCB)
catch
end

end  % #rectangleButtonUpCB
%__________________________________________________________
%% #rectangleCornerCB
%
function shoulderGui_rectangleCornerCB(h, evd)

fig = hfigure(h);
if evd.Button == 3
    shoulderGui_changeAngle(fig)
    return
end

appData = getAppData(fig);
appData.rectangle.activePoint = h;
setAppData(fig, appData)

set(appData.rectangle.activePoint, 'MarkerFaceColor', ...
    appData.rectanglePrps.point.markerFaceColorSelected)

set(appData.rectangle.points(1), 'ButtonDownFcn', '')
set(appData.rectangle.points(2), 'ButtonDownFcn', '')

set(fig, 'WindowButtonMotionFcn', {@shoulderGui_rectangleButtonMotionCB, fig})
set(fig, 'WindowButtonUpFcn', {@shoulderGui_rectangleButtonUpCB, fig})
drawnow

end  % #rectangleCornerCB
%__________________________________________________________
%% #changeAngle
%
function shoulderGui_changeAngle(fig)

rectangle = getAppData(fig, 'rectangle');
curAngle = rectangle.angle;
answer = inputdlg({'Rectangle angle [degrees]:'},'Rectangle angle', [1, 35], {num2str(curAngle)});
if isempty(answer)
    return
end

newAngle = str2num(answer{1}); %#ok<ST2NM>
if numel(newAngle) ~= 1
    hDlg = errordlg('The value must be numeric', 'Invalid value');
    waitfor(hDlg)
    shoulderGui_changeAngle(fig)
    return
end

if newAngle < -45 || newAngle > 45
    hDlg = errordlg('The value must be between -45 and +45', 'Invalid value');
    waitfor(hDlg)
    shoulderGui_changeAngle(fig)
    return
end

if newAngle == curAngle
    return
end

rectangle.angle = newAngle;

x0 = get(rectangle.points(1), 'XData');
y0 = get(rectangle.points(1), 'YData');
x1 = get(rectangle.points(2), 'XData');
y1 = get(rectangle.points(2), 'YData');

[lineCoords, extent, x1, y1] = shoulderGui_getRectangleLineCoords(x0, y0, x1, y1, newAngle);
[lineCoords, extent, x1, y1] = shoulderGui_checkRectangleInAxLimits(lineCoords, extent, x0, y0, x1, y1, newAngle, fig);

for ii = 1:numel(lineCoords)
    set(rectangle.lines(ii), 'XData', lineCoords(ii).x, 'YData', lineCoords(ii).y)
end
set(rectangle.points(2), 'XData', x1, 'YData', y1)

rectangle.extent = extent;
setAppData(fig, rectangle, 'rectangle')

end  % #changeAngle
%__________________________________________________________
%% #rectangleCornersSwitch
%
function shoulderGui_rectangleCornersSwitch(appData, doShow)

rectangle = appData.rectangle;
if doShow
    set(rectangle.points(1), 'ButtonDownFcn', @shoulderGui_rectangleCornerCB)
    set(rectangle.points(2), 'ButtonDownFcn', @shoulderGui_rectangleCornerCB)
    set(rectangle.points(1), 'Marker', appData.rectanglePrps.point.marker)
    set(rectangle.points(2), 'Marker', appData.rectanglePrps.point.marker)
    uistack(rectangle.points(1), 'top')
    uistack(rectangle.points(2), 'top')
else
    set(rectangle.points(1), 'Marker', 'none')
    set(rectangle.points(2), 'Marker', 'none')
    set(rectangle.points(1), 'ButtonDownFcn', '')
    set(rectangle.points(2), 'ButtonDownFcn', '')
end

end  % #rectangleCornersSwitch
%__________________________________________________________
%% #drawRectangle
%
function shoulderGui_drawRectangle(fig, x0, y0, x1, y1, angle, varargin)

appData = getAppData(fig);

appData.rectangle = struct('lines', [], 'points', [], 'angle', [], 'extent', []);

if ~isempty(varargin) && isstruct(varargin{1})
    lineCoords = varargin{1};
    extent = varargin{2};
else
    [lineCoords, extent, x1, y1] = shoulderGui_getRectangleLineCoords(x0, y0, x1, y1, angle);
end

lnPrp           = struct;
lnPrp.Parent    = appData.ax;
lnPrp.LineWidth = appData.rectanglePrps.line.width;
lnPrp.Color     = appData.rectanglePrps.line.color;
lnPrp.lineStyle = appData.rectanglePrps.line.lineStyle;

for ii = 1:numel(lineCoords)
    lnPrp.XData     = lineCoords(ii).x;
    lnPrp.YData     = lineCoords(ii).y;
    appData.rectangle.lines(ii) = line(lnPrp);
end

pointPrp0 = struct;
pointPrp0.Parent             = appData.ax;
pointPrp0.Marker             = appData.rectanglePrps.point.marker;
pointPrp0.MarkerSize         = appData.rectanglePrps.point.markerSize;
pointPrp0.MarkerEdgeColor    = appData.rectanglePrps.point.markerEdgeColor;
pointPrp0.MarkerFaceColor    = appData.rectanglePrps.point.markerFaceColor;

pointPrp        = pointPrp0;
pointPrp.XData  = x0;
pointPrp.YData  = y0;
appData.rectangle.points(1) = line(pointPrp);

pointPrp        = pointPrp0;
pointPrp.XData  = x1;
pointPrp.YData  = y1;
appData.rectangle.points(2) = line(pointPrp);

appData.rectangle.angle = angle;
appData.rectangle.extent = extent;

setAppData(fig, appData)

end  % #drawRectangle
%__________________________________________________________
%% #getRectangleLineCoords
%
function [lineCoords, extent, x1, y1] = shoulderGui_getRectangleLineCoords(x0, y0, x1, y1, angle)

% angle is always between (-45, +45) degrees

lineCoords = struct('x', {}, 'y', {});
extent = struct('xMin', [], 'xMax', [], 'yMin', [], 'yMax', []);

if angle == 0
    lineCoords(1).x = [1,1]*x0;
    lineCoords(1).y = [y0,y1];

    lineCoords(2).x = [x0,x1];
    lineCoords(2).y = [1,1]*y0;

    lineCoords(3).x = [1,1]*x1;
    lineCoords(3).y = [y0,y1];

    lineCoords(4).x = [x0,x1];
    lineCoords(4).y = [1,1]*y1;

    extent.xMin = min(x0, x1);
    extent.xMax = max(x0, x1);
    extent.yMin = min(y0, y1);
    extent.yMax = max(y0, y1);
else
    R = [cosd(angle), -sind(angle);sind(angle), cosd(angle)];
    xy1Norm = [x1 - x0; y1 - y0];
    xy2Norm = [x1 - x0; 0];
    xy3Norm = [0; y1 - y0];

    xy1Rot = R*xy1Norm + [x0; y0];
    xy2Rot = R*xy2Norm + [x0; y0];
    xy3Rot = R*xy3Norm + [x0; y0];

    lineCoords(1).x = [x0,xy3Rot(1)];
    lineCoords(1).y = [y0,xy3Rot(2)];

    lineCoords(2).x = [x0,xy2Rot(1)];
    lineCoords(2).y = [y0,xy2Rot(2)];

    lineCoords(3).x = [xy2Rot(1),xy1Rot(1)];
    lineCoords(3).y = [xy2Rot(2),xy1Rot(2)];

    lineCoords(4).x = [xy3Rot(1),xy1Rot(1)];
    lineCoords(4).y = [xy3Rot(2),xy1Rot(2)];

    extent.xMin = min([x0, xy2Rot(1), xy3Rot(1), xy1Rot(1)]);
    extent.xMax = max([x0, xy2Rot(1), xy3Rot(1), xy1Rot(1)]);
    extent.yMin = min([y0, xy2Rot(2), xy3Rot(2), xy1Rot(2)]);
    extent.yMax = max([y0, xy2Rot(2), xy3Rot(2), xy1Rot(2)]);

    x1 = xy1Rot(1);
    y1 = xy1Rot(2);
end

end  % #getRectangleLineCoords
%__________________________________________________________
%% #checkRectangleInAxLimits
%
function [lineCoords, extent, x1, y1] = shoulderGui_checkRectangleInAxLimits(lineCoords, extent, x0, y0, x1, y1, angle, fig)

ax = getAppData(fig , 'ax');
axLimits = [get(ax, 'XLim'), get(ax, 'YLim')];

if x1 >= axLimits(1) && x1 <= axLimits(2) && y1 >= axLimits(3) && y1 <= axLimits(4)
    return
end

intersectionPoint = nan;
redFactor = inf;

axLines = [
    axLimits(1), axLimits(2), axLimits(3), axLimits(3);
    axLimits(1), axLimits(2), axLimits(4), axLimits(4);
    axLimits(1), axLimits(1), axLimits(3), axLimits(4);
    axLimits(2), axLimits(2), axLimits(3), axLimits(4);
    ];

for ii = 1:4
    [intersectionPoint_ii, redFactor_ii] = getLineIntersectionPoint(x0, y0, x1, y1, axLines(ii,1), axLines(ii,3), axLines(ii,2), axLines(ii,4));
    if isnan(intersectionPoint_ii)
        continue
    end

    if redFactor_ii < redFactor
        intersectionPoint = intersectionPoint_ii;
        redFactor = redFactor_ii;
    end
end % for ii

if isnan(intersectionPoint)
    return
end

x1 = intersectionPoint(1);
y1 = intersectionPoint(2);


R = [cosd(angle), -sind(-angle);sind(-angle), cosd(-angle)];
xy1Norm = [x1 - x0; y1 - y0];
xy1Rot = R*xy1Norm + [x0; y0];

[lineCoords, extent, x1, y1] = shoulderGui_getRectangleLineCoords(x0, y0, xy1Rot(1), xy1Rot(2), angle);

end  % #checkRectangleInAxLimits
%__________________________________________________________
%% #getLineIntersectionPoint
%
function [intersectionPoint, redFactor] = getLineIntersectionPoint(x0, y0, x1, y1, x2, y2, x3, y3)
% https://en.wikipedia.org/wiki/Line%E2%80%93line_intersection
% Given two points on each line segment

intersectionPoint = nan;
redFactor = nan;

d = (x0 - x1)*(y2 - y3) - (y0 - y1)*(x2 - x3);
t = ((x0 - x2)*(y2 - y3) - (y0 - y2)*(x2 - x3))/d;
u = ((x0 - x2)*(y0 - y1) - (y0 - y2)*(x0 - x1))/d;

if t < 0 || t > 1 || u < 0 || u > 1
    return
end

x1 = x0 + t*(x1 - x0);
y1 = y0 + t*(y1 - y0);

intersectionPoint = [x1, y1];
redFactor = t;

end % #getClosestPoint
%__________________________________________________________
%% #checkGroupNames
%
function [ok, appData] = shoulderGui_checkGroupNames(appData)

ok = false;
pnlData = getAppData(appData.imgPnl);

groupNm1 = get(pnlData.group1Edit, 'String');
groupNm2 = get(pnlData.group2Edit, 'String');

if isempty(groupNm1)
    errordlg('The name of group 1 cannot be empty!', 'Invalid name')
    return
end
if isempty(groupNm2)
    errordlg('The name of group 2 cannot be empty!', 'Invalid name')
    return
end
if strcmpi(groupNm1, groupNm2)
    errordlg('The names must be unique!', 'Invalid names')
    return
end

appData.groups(1).name = groupNm1;
appData.groups(2).name = groupNm2;

ok = true;

end  % #checkGroupNames
%__________________________________________________________
%% #updateGroupNamesInCtrlPnl
%
function shoulderGui_updateGroupNamesInCtrlPnl(fig, groups)

pnlData = getAppData(getAppData(fig, 'ctrlPnl'));

set(pnlData.(pnlData.firstGroupName), 'String',...
    sprintf('%s %s', pnlData.groupBaseStr, groups(1).name))
set(pnlData.(pnlData.secondGroupName), 'String',...
    sprintf('%s %s', pnlData.groupBaseStr, groups(2).name))

end  % #updateGroupNamesInCtrlPnl
%__________________________________________________________
%% #addShoulderPoint
%
function shoulderGui_addShoulderPoint(h, evd)

fig = hfigure(h);
% Deselect any selected point
if ~isempty(getAppData(fig, 'selectedPoint'))
    shoulderGui_switchPointSelection(getAppData(fig, 'selectedPoint'), fig, false)
end

appData = getAppData(fig);

if appData.nextIsSecondPoint
    x1 = get(appData.lastCreatedPoint, 'XData');
    y1 = get(appData.lastCreatedPoint, 'YData');
    x2 = evd.IntersectionPoint(1);
    y2 = evd.IntersectionPoint(2);

    % Create connecting line
    lnPpr               = appData.shoulderLinePrp;
    lnPpr.XData         = [x1, x2];
    lnPpr.YData         = [y1, y2];
    connLine            = line(lnPpr);

    % Create right should point
    lnPpr = appData.rightShoulderPointPrp;
    lnPpr.XData = x2;
    lnPpr.YData = y2;
    point = line(lnPpr);

    uistack(appData.lastCreatedPoint,'top')
    drawnow

    % Add line and point to userdata points
    set(point, 'UserData', [appData.lastCreatedPoint, connLine, gobjects(1)])
    set(appData.lastCreatedPoint, 'UserData', [point, connLine, gobjects(1)])

    appData.activeShoulderPoints(end+1) = appData.lastCreatedPoint;

    appData.nextIsSecondPoint = false;
    appData.lastCreatedPoint = '';
else
    lnPpr = appData.leftShoulderPointPrp;
    lnPpr.XData = evd.IntersectionPoint(1);
    lnPpr.YData = evd.IntersectionPoint(2);
    point = line(lnPpr);

    appData.nextIsSecondPoint = true;
    appData.lastCreatedPoint = point;
end

setAppData(fig, appData)

end  % #addShoulderPoint
%__________________________________________________________
%% #shoulderPointCB
%
function shoulderGui_shoulderPointCB(h, evd)

fig = hfigure(h);

% Deselect any selected point
if ~isempty(getAppData(fig, 'selectedPoint'))
    shoulderGui_switchPointSelection(getAppData(fig, 'selectedPoint'), fig, false)
end

if evd.Button == 1
    % Capture current location
    setAppData(fig, {get(h, 'XData');get(h, 'YData')}, 'curPointLoc');
    % left click == start moving point
    set(fig, 'WindowButtonMotionFcn', {@shoulderGui_moveShoulderPoint, h})
    set(fig, 'WindowButtonUpFcn', {@shoulderGui_endMoveShoulderPoint, fig, h})
elseif evd.Button == 3
    appData = getAppData(fig);
    %    right click == remove point (and the connected point and connecting line)
    if h == appData.lastCreatedPoint
        appData.nextIsSecondPoint = false;
        appData.lastCreatedPoint = '';
    end
    userData = get(h, 'UserData');
    if ~isempty(userData)
        delete(userData(1));
        delete(userData(2));
        if ishghandle(userData(3))
            delete(userData(3));
        end
    end
    appData = shoulderGui_removeShoulderPoint(h, appData);
    setAppData(fig, appData)
end

end  % #shoulderPointCB
%__________________________________________________________
%% #removeShoulderPoint
%
function appData = shoulderGui_removeShoulderPoint(h, appData)

for ii = 1:numel(appData.activeShoulderPoints)
    userData = get(h, 'UserData');
    if appData.activeShoulderPoints(ii) == h || (numel(userData) > 0 && appData.activeShoulderPoints(ii) == userData(1))
        appData.activeShoulderPoints(ii) = [];
        break;
    end
end % for ii

delete(h)

end  % #removeShoulderPoint
%__________________________________________________________
%% #moveShoulderPoint
%
function shoulderGui_moveShoulderPoint(~, evd, hPoint)

x = evd.IntersectionPoint(1);
y = evd.IntersectionPoint(2);

set(hPoint, 'XData', x, 'YData', y)
userData = get(hPoint, 'UserData');
if isempty(userData)
    return
end

otherPoint = userData(1);
xOther = get(otherPoint, 'XData');
yOther = get(otherPoint, 'YData');
connLine = userData(2);
set(connLine, 'XData', [x, xOther], 'YData', [y, yOther])

if ishghandle(userData(3))
    set(userData(3), 'Position', [mean([x, xOther]), 'YData', mean([y, yOther]), 0])
end

end  % #moveShoulderPoint
%__________________________________________________________
%% #endMoveShoulderPoint
%
function shoulderGui_endMoveShoulderPoint(~, ~, fig, hPoint)

set(fig, 'WindowButtonMotionFcn', '')
set(fig, 'WindowButtonUpFcn', '')
curPointLoc = getAppData(fig, 'curPointLoc');
if all(curPointLoc{1} == get(hPoint, 'XData')) && all(curPointLoc{2} == get(hPoint, 'YData'))
    setAppData(fig, {}, 'curPointLoc')
    % Activate point
    shoulderGui_switchPointSelection(hPoint, fig, true) % Sometimes gives an error

    return
end

end  % #endMoveShoulderPoint
%__________________________________________________________
%% #saveShoulderData
%
function appData = shoulderGui_saveShoulderData(appData, groupInd, stepInd)

lastCreatedInList = false;
appData.selectedPoint = [];

for ii = 1:numel(appData.activeShoulderPoints)
    if appData.lastCreatedPoint == appData.activeShoulderPoints(ii)
        lastCreatedInList = true;
    end
    if groupInd == 1
        userData = get(appData.activeShoulderPoints(ii), 'UserData');
        set(appData.activeShoulderPoints(ii), 'MarkerFaceColor', appData.inactiveShoulderPointColor)
        set(userData(1), 'MarkerFaceColor', appData.inactiveShoulderPointColor)
        set(appData.activeShoulderPoints(ii), 'MarkerSize', appData.baseMarkerSize)
        set(userData(1), 'MarkerSize', appData.baseMarkerSize)
        set(userData(2), 'Color', appData.inactiveShoulderLineColor)
        set(appData.activeShoulderPoints(ii), 'ButtonDownFcn', '')
        set(userData(1), 'ButtonDownFcn', '')
    end
end % for ii

if groupInd == 1
    appData = shoulderGui_addPointsToData(appData, 1, stepInd, appData.activeShoulderPoints);
end
if groupInd == 2
    appData = shoulderGui_addPointsToData(appData, 1, stepInd, appData.inactiveShoulderPoints);
    appData = shoulderGui_addPointsToData(appData, 2, stepInd, appData.activeShoulderPoints);
    shoulderGui_deletePoints(appData.activeShoulderPoints)
    shoulderGui_deletePoints(appData.inactiveShoulderPoints)
end

if ~lastCreatedInList && ~isempty(appData.lastCreatedPoint)
    delete(appData.lastCreatedPoint)
end

if groupInd == 1
    if ~isempty(appData.inactiveShoulderPoints)
        appData = shoulderGui_activatePoints(appData);
    else
        appData.inactiveShoulderPoints = appData.activeShoulderPoints;
        appData.activeShoulderPoints = gobjects(0);
    end
else
    appData.inactiveShoulderPoints = gobjects(0);
end

appData.nextIsSecondPoint = false;
appData.lastCreatedPoint = '';
drawnow

end  % #saveShoulderData
%__________________________________________________________
%% #deletePoints
%
function shoulderGui_deletePoints(points)

for ii = 1:numel(points)
    userData = get(points(ii), 'UserData');
    delete(userData(1));
    delete(userData(2))
    if ishghandle(userData(3))
        delete(userData(3))
    end
    delete(points(ii))
end % for ii

end  % #deletePoints
%__________________________________________________________
%% #addPointsToData
%
function appData = shoulderGui_addPointsToData(appData, groupInd, stepInd, points)

dataInd = appData.stepInd2dataInd(stepInd);

appData.groups(groupInd).shoulders{dataInd,1} = (stepInd - 1)*appData.interval + 1;
appData.groups(groupInd).shoulders{dataInd,2} = numel(points);

pointData = nan(numel(points), 4);

for ii = 1:numel(points)
    userData = get(points(ii), 'UserData');
    pointData(ii,1) = get(points(ii), 'XData');
    pointData(ii,2) = get(points(ii), 'YData');
    pointData(ii,3) = get(userData(1), 'XData');
    pointData(ii,4) = get(userData(1), 'YData');
    if ishghandle(userData(3))
        warning('Not supported')
        %pointData(ii,5) = double(get(userData(3), 'String')) - 64;
    end
end % for ii

if numel(points) > 0 && appData.analysisStepInd > appData.lastStepWithProcessedData
    appData.lastStepWithProcessedData = appData.analysisStepInd;

end

appData.groups(groupInd).shoulders{dataInd,3} = pointData;

end  % #addPointsToData
%__________________________________________________________
%% #activatePoints
%
function appData = shoulderGui_activatePoints(appData)

inactivePoints = appData.inactiveShoulderPoints;
appData.inactiveShoulderPoints = appData.activeShoulderPoints;
appData.activeShoulderPoints = inactivePoints;
appData.selectedPoint = [];

for ii = 1:numel(inactivePoints)
    userData = get(inactivePoints(ii), 'UserData');
    set(inactivePoints(ii), 'MarkerFaceColor', appData.leftShoulderPointColor)
    set(userData(1), 'MarkerFaceColor', appData.rightShoulderPointColor)
    set(inactivePoints(ii), 'MarkerSize', appData.baseMarkerSize)
    set(userData(1), 'MarkerSize', appData.baseMarkerSize)
    set(userData(2), 'Color', appData.activeShoulderLineColor)
    set(inactivePoints(ii), 'ButtonDownFcn', @shoulderGui_shoulderPointCB)
    set(userData(1), 'ButtonDownFcn', @shoulderGui_shoulderPointCB)
end % for ii

end  % #activatePoints
%__________________________________________________________
%% #setPointsBasedOnData
%
function appData = shoulderGui_setPointsBasedOnData(appData)

if appData.minorStepInd == 1
    firstActive = true;
    secondActive = false;
else
    secondActive = true;
    firstActive = false;
end

dataInd = appData.stepInd2dataInd(appData.analysisStepInd);

if appData.groups(1).shoulders{dataInd,2} > 0
    % Create active points
    pointData = appData.groups(1).shoulders{dataInd,3};
    firstGroupPoint = shoulderGui_createPointsFromData(pointData, firstActive, appData);
else
    firstGroupPoint = gobjects(0);
end
if appData.groups(2).shoulders{dataInd,2} > 0
    % Create inactive points
    pointData = appData.groups(2).shoulders{dataInd,3};
    secondGroupPoints = shoulderGui_createPointsFromData(pointData, secondActive, appData);
else
    secondGroupPoints = gobjects(0);
end

if appData.minorStepInd == 1
    appData.activeShoulderPoints = firstGroupPoint;
    appData.inactiveShoulderPoints = secondGroupPoints;
else
    appData.activeShoulderPoints = secondGroupPoints;
    appData.inactiveShoulderPoints = firstGroupPoint;
end

end  % #setPointsBasedOnData
%__________________________________________________________
%% #createPointsFromData
%
function points = shoulderGui_createPointsFromData(pointData, isActive, appData)

points = gobjects(size(pointData,1),1);
for ii = 1:size(pointData,1)
    lnPpr               = appData.shoulderLinePrp;
    lnPpr.XData         = [pointData(ii,1), pointData(ii,3)];
    lnPpr.YData         = [pointData(ii,2), pointData(ii,4)];
    if ~isActive
        lnPpr.Color     = appData.inactiveShoulderLineColor;
    end
    connLine            = line(lnPpr);

    lnPpr = appData.leftShoulderPointPrp;
    if ~isActive
        lnPpr.MarkerFaceColor = appData.inactiveShoulderPointColor;
        lnPpr.ButtonDownFcn = '';
    end
    lnPpr.XData = pointData(ii,1);
    lnPpr.YData = pointData(ii,2);
    leftPoint = line(lnPpr);

    lnPpr = appData.rightShoulderPointPrp;
    if ~isActive
        lnPpr.MarkerFaceColor = appData.inactiveShoulderPointColor;
        lnPpr.ButtonDownFcn = '';
    end
    lnPpr.XData = pointData(ii,3);
    lnPpr.YData = pointData(ii,4);
    rightPoint = line(lnPpr);

    if size(pointData,2) == 5 && ~isnan(pointData(ii,5))
        shoulderTextPrp = appData.shoulderTextPrp;
        shoulderTextPrp.String = char(64 + pointData(ii,5));
        shoulderTextPrp.Position = [mean(pointData(ii,[1,3])), mean(pointData(ii,[2,4])), 0];
        hText = text(shoulderTextPrp);
    else
        hText = gobjects(1);
    end

    set(leftPoint, 'UserData', [rightPoint, connLine, hText])
    set(rightPoint, 'UserData', [leftPoint, connLine, hText])
    points(ii) = leftPoint;
end % for ii

end  % #createPointsFromData
%__________________________________________________________
%% #clearPoints
%
function appData = shoulderGui_clearPoints(appData)

shoulderGui_deletePoints(appData.activeShoulderPoints)
shoulderGui_deletePoints(appData.inactiveShoulderPoints)
appData.activeShoulderPoints = gobjects(0);
appData.inactiveShoulderPoints = gobjects(0);

end  % #clearPoints
%__________________________________________________________
%% #initSaveFile
%
function [succes, appData] = shoulderGui_initSaveFile(appData)

if ~isempty(appData.dataFilename)
    filename = appData.dataFilename;
else
    [succes, pd, filename] = shoulderGui_chooseSaveFilename();
    if ~succes
        return
    end
    if isfile(filename)
        delete(filename)
    end
    appData.dataPd = pd;
    appData.dataFilename = filename;
end

dataFlNmLabel = getAppData(appData.ctrlPnl, 'dataFlNmLabel');
[~, file, ext] = fileparts(filename);
set(dataFlNmLabel, 'String', append(file, ext))

appData.dataFile = matfile(filename,'Writable',true);
succes = true;

end  % #initSaveFile
%__________________________________________________________
%% #saveData2file
%
function shoulderGui_saveData2file(appData, field)

switch field
    case 'all'
        shoulderGui_saveData2file(appData, 'videoData')
        shoulderGui_saveData2file(appData, 'interval')
        shoulderGui_saveData2file(appData, 'rectangle')
        shoulderGui_saveData2file(appData, 'groups')
        data = load(appData.dataFilename);
        save(appData.dataFilename, '-struct', 'data');
    case 'videoData'
        videoSaveData = struct;
        if isempty(appData.videoData)
            return
        end
        videoSaveData.frameRate = appData.videoData.vidObj.FrameRate;
        videoSaveData.duration = appData.videoData.vidObj.Duration;

        [videoSaveData.pdParts, videoSaveData.file] = shoulderGui_getFileParts(appData.videoData.flNm, appData.dataPd);
        appData.dataFile.video = videoSaveData;
    case 'interval'
        appData.dataFile.analysisStepCount = appData.analysisStepCount;
        appData.dataFile.interval = appData.interval;
    case 'rectangle'
        appData.dataFile.rectangle = shoulderGui_getRectangleSaveData(appData.rectangle);
    case 'groups'
        appData.dataFile.groups = appData.groups;
        appData.dataFile.lastStepWithProcessedData = appData.lastStepWithProcessedData;
    otherwise
        error('Unknown field: %s', field)
end

end  % #saveData2file
%__________________________________________________________
%% #getFileParts
%
function [pdParts, file] = shoulderGui_getFileParts(videoFilename, dataPd)

[pd, fl, ext] = fileparts(videoFilename);
file = [fl ext];
pdRel = relativepath(pd, dataPd);
pdParts = strsplit(pdRel, filesep);
pdParts(strcmpi(pdParts, '')) = [];

end  % #getFileParts
%__________________________________________________________
%% #getRectangleSaveData
%
function saveData = shoulderGui_getRectangleSaveData(rectangleData)

if isempty(rectangleData)
    saveData = '';
    return
end

saveData = struct;
saveData.angle = rectangleData.angle;
saveData.extent = rectangleData.extent;

lines = struct('x', {}, 'y', {});
for ii = 1:numel(rectangleData.lines)
    lines(ii).x = get(rectangleData.lines(ii), 'XData');
    lines(ii).y = get(rectangleData.lines(ii), 'YData');
end % for ii
saveData.lines = lines;

points = struct('x', {}, 'y', {});
for ii = 1:numel(rectangleData.points)
    points(ii).x = get(rectangleData.points(ii), 'XData');
    points(ii).y = get(rectangleData.points(ii), 'YData');
end % for ii
saveData.points = points;

end  % #getRectangleSaveData
%__________________________________________________________
%% #chooseSaveFilename
%
function [succes, path, filename] = shoulderGui_chooseSaveFilename()

succes = false;
filename = '';

dataPd = fullfile(cd, 'data', 'output');
if ~isfolder(dataPd)
    dataPd = cd;
end

[file, path] = uiputfile('*.mat', 'Choose a file for saving the analysis data', fullfile(dataPd, 'rorationData.mat'));
if file == 0
    warndlg('A save file must be chosen to continue!', 'Warning', '-modal');
else
    filename = fullfile(path, file);
    succes = true;
end

end  % #chooseSaveFilename
%__________________________________________________________
%% #checkShoulders
%
function appData = shoulderGui_checkShoulders(appData)

if size(appData.groups(1).shoulders, 1) == appData.analysisStepCount
    return
end

frameNrsInData = appData.groups(1).shoulders(:,1);
emptyInd = cellfun(@isempty,frameNrsInData);
frameNrsInData(emptyInd) = {NaN};
frameNrsInData = cell2mat(frameNrsInData);
frameNrPerStep = 1:appData.interval:appData.interval*appData.analysisStepCount;
[diffNr, diffInd] = setdiff(frameNrsInData, frameNrPerStep);
otherInd = diffInd(~isnan(diffNr));

appData.stepInd2dataInd = setdiff(1:size(appData.groups(1).shoulders, 1), otherInd);

end  % #checkShoulders
%__________________________________________________________
%% #convertToFrameNr
%
function shoulderGui_convertToFrameNr(filename)

data = load(filename);

for ii = 1:numel(data.groups)
    for jj = 1:size(data.groups(ii).shoulders,1)
        data.groups(ii).shoulders{jj,1} = (data.groups(ii).shoulders{jj,1} - 1)*data.interval + 1;
    end % for jj
end % for ii

save(filename, '-struct', 'data')

end  % #convertToFrameNr
%__________________________________________________________
%% #addRectangleFromData
%
function shoulderGui_addRectangleFromData(fig, rectangleS)

if isfield(rectangleS, 'main')
    rectangleS = shoulderGui_getRectangleFromOldDataStruct(rectangleS);
end

x0 = rectangleS.points(1).x;
y0 = rectangleS.points(1).y;
x1 = rectangleS.points(2).x;
y1 = rectangleS.points(2).y;

angle = rectangleS.angle;
extent = rectangleS.extent;

lineCoords = struct('x', {}, 'y', {});
for ii = 1:numel(rectangleS.lines)
    lineCoords(ii).x = rectangleS.lines(ii).x;
    lineCoords(ii).y = rectangleS.lines(ii).y;
end % for ii
shoulderGui_drawRectangle(fig, x0, y0, x1, y1, angle, lineCoords, extent);

end  % #addRectangleFromData
%__________________________________________________________
%% #getRectangleFromOldDataStruct
%
function rectangleS = shoulderGui_getRectangleFromOldDataStruct(rectangleOldS)

main  = rectangleOldS.main;

x0 = main.ll.x;
y0 = main.ll.y;
x1 = main.ur.x;
y1 = main.ur.y;

rectangleS.points(1).x = x0;
rectangleS.points(1).y = y0;
rectangleS.points(2).x = x1;
rectangleS.points(2).y = y1;

rectangleS.angle = main.angle;

[lineCoords, extent, ~, ~] = shoulderGui_getRectangleLineCoords(x0, y0, x1, y1, main.angle);
rectangleS.extent = extent;

rectangleS.lines = lineCoords;

end  % #addRectangleFromData
%__________________________________________________________

%% #switchPointSelection
%
function shoulderGui_switchPointSelection(hPoint, fig, isSelected)

if isSelected
    userData = get(hPoint, 'UserData');
    if isempty(userData)
        return
    end

    setAppData(fig, hPoint, 'selectedPoint')
    % Make point selected visually
    markerSize = getAppData(fig, 'selectedMarkerSize');
    % Add keypressfcn
    set(fig, 'WindowKeyPressFcn', @shoulderGui_shoulderKeyPress)
else
    markerSize = getAppData(fig, 'baseMarkerSize');
    set(fig, 'WindowKeyPressFcn', '')
    setAppData(fig, [], 'selectedPoint')
end

set(hPoint, 'MarkerSize', markerSize)
userData = get(hPoint, 'UserData');
otherPoint = userData(1);
set(otherPoint, 'MarkerSize', markerSize)

end  % #switchPointSelection
%__________________________________________________________
%% #shoulderKeyPress
%
function shoulderGui_shoulderKeyPress(h, evd)

fig = hfigure(h);
rectangle = getAppData(fig, 'rectangle');
if ~numel(rectangle.subs)
    return
end
keys = {rectangle.subs.label};

if ~(any(strcmpi(evd.Key, keys)) || strcmpi(evd.Key, 'delete'))
    return
end

hPoint = getAppData(fig, 'selectedPoint');
userData = get(hPoint, 'UserData');
otherPoint = userData(1);
otherUserData = get(otherPoint, 'UserData');

if strcmpi(evd.Key, 'delete')
    % Delete label
    if ishghandle(userData(3))
        delete(userData(3))
        userData(3) = gobjects(1);
        otherUserData(3) = gobjects(1);
    end
else
    x = get(hPoint, 'XData');
    y = get(hPoint, 'YData');

    xOther = get(otherPoint, 'XData');
    yOther = get(otherPoint, 'YData');

    shoulderTextPrp = getAppData(fig, 'shoulderTextPrp');
    shoulderTextPrp.String = upper(evd.Key);
    shoulderTextPrp.Position = [mean([x, xOther]), mean([y, yOther]), 0];
    hText = text(shoulderTextPrp);

    otherUserData(3) = hText;
    userData(3) = hText;
end
set(hPoint, 'UserData', userData);
set(otherPoint, 'UserData', otherUserData);

shoulderGui_switchPointSelection(hPoint, fig, false)

end  % #shoulderKeyPress
%__________________________________________________________
%% #fixPathsInFile
%
function shoulderGui_fixPathsInFile(filename, videoPath)

if isdir(filename)
    dirInfo = dir(filename);
    dirInfo([dirInfo.isdir]) = [];
    filenames = cellfun(@fullfile, {dirInfo.folder}, {dirInfo.name}, 'UniformOutput',false);
else
    filenames = {filename};
end

for i = 1:numel(filenames)
    filename = filenames{i};
    data = load(filename);
    dataPd = fileparts(filename);
    [~, fl, ext] = fileparts(data.video.filename);
    [data.video.pdParts, data.video.file] = shoulderGui_getFileParts(fullfile(videoPath, [fl, ext]), dataPd);
    data.video = rmfield(data.video, 'filename');
    save(filename, '-struct', 'data');
end % for i

end % #fixPathsInFile
%__________________________________________________________
%% #convertOldMat2new
%
function shoulderGui_convertOldMat2new(filename)

data = load(filename);

appData = struct;
fldNms = fieldnames(data);
for ii = 1:numel(fldNms)
    appData.(fldNms{ii}) = data.(fldNms{ii});
end % for ii

appData.videoData.vidObj = struct;
appData.videoData.vidObj.FrameRate = appData.video.frameRate;
appData.videoData.vidObj.Duration = appData.video.duration;
appData.videoData.flNm = appData.video.filename;

appData.dataPd = fileparts(filename);
appData.dataFilename = filename;

delete(filename)
[~, appData] = shoulderGui_initSaveFile(appData);
shoulderGui_saveData2file(appData, 'all')
data = load(filename);
save(filename, '-struct', 'data');

end  % #convertOldMat2new
%__________________________________________________________
%% #zoomSwitch
%
function shoulderGui_zoomSwitch(h, ~)

fig = hfigure(h);
appData = getAppData(fig);
if isempty(appData.rectangle)
    set(h, 'Value', get(h, 'Min'))
    return
end

isSelected = get(h, 'Value') == get(h, 'Max');

if isSelected
    shoulderGui_zoomAxes(appData)
else
    shoulderGui_resetAxZoom(appData)
end

end  % #zoomSwitch
%__________________________________________________________
%% #zoomAxes
%
function shoulderGui_zoomAxes(appData)

buffer = 50;
xLim = [max(appData.rectangle.extent.xMin - buffer,  appData.orgImgAxLimit(1)), min(appData.rectangle.extent.xMax + buffer, appData.orgImgAxLimit(2))];
yLim = [max(appData.rectangle.extent.yMin - buffer,  appData.orgImgAxLimit(3)), min(appData.rectangle.extent.yMax + buffer, appData.orgImgAxLimit(4))];
set(appData.ax, 'XLim', xLim)
set(appData.ax, 'YLim', yLim)
drawnow

end  % #zoomAxes
%__________________________________________________________
%% #resetAxZoom
%
function shoulderGui_resetAxZoom(appData)

set(appData.ax, 'XLim', appData.orgImgAxLimit(1:2))
set(appData.ax, 'YLim', appData.orgImgAxLimit(3:4))
drawnow

end  % #resetAxZoom
%__________________________________________________________
%% #qqq
%
function shoulderGui_qqq

end  % #qqq
%__________________________________________________________
%% #rrr
%
function varargout = shoulderGui_rrr(action, varargin)

if nargout
    varargout = cell(1, nargout);
end

switch action
    case 'fcnHandle'
        varargout{1} = eval(['@shoulderGui_rrr_', varargin{1}]);
    case 'sss'

    otherwise
        error('.')
end

% _________________________________________________________
% _rrr_sub1
    function shoulderGui_rrr_sub1

    end  % _rrr_sub1

end  % #rrr
%__________________________________________________________