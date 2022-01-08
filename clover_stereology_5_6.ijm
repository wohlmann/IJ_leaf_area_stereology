macro "Clover leaf stereology" {
		Dialog.create("Options");
		Dialog.addChoice("Grid Type: ", newArray("Crosses", "Lines", "[Horizontal Lines]", "Points", "Circles" ), "Crosses");
		Dialog.addCheckbox("random startpoint", true);
		Dialog.addCheckbox("bold grid", true);
		Dialog.show;
		GR = Dialog.getChoice();					// grid type
		ra = Dialog.getCheckbox();					//random
		bd = Dialog.getCheckbox();					//bold
		NS=1;
		if(ra==true){
			ra="random";
		}
		if(bd==true){
			bd="bold";
		}		
		run("Close All");
		print("\\Clear");
		print("Reset: log, Results, ROI Manager");
		run("Clear Results");
		updateResults;
		roiManager("reset");
		//get filedata:
		dir1=getDirectory("Please choose source directory ");
		list=getFileList(dir1);
		dir2=getDirectory("_Please choose destination directory ");
		print("Method: point count for Area");
		Sname=getString("sample name:", "");
		print("Sample name: "+Sname+""); 
		dir3 = dir2 + ""+Sname+"" + File.separator;
		File.makeDirectory(dir3);
		if (!File.exists(dir3)){
			exit("Unable to create directory - check permissions");
			}
		//clean up:
		while (nImages>0) {				
			selectImage(nImages);
			close();
		}
		run("Set Measurements...", "area redirect=None decimal=1");
		getDateAndTime(year, month, week, day, hour, min, sec, msec);
		print("Start measurements at: "+day+"/"+month+"/"+year+" :: "+hour+":"+min+":"+sec+"");
		lineWidth=9;
		print("_");
		//counters:
		No=0;
		N=0;
		//start:
		for (i=0; i<list.length; i++) {
			path = dir1+list[i];
			roiManager("reset");
			open(""+path+"");
			actimage = getTitle();
			title1= getTitle;
			title2 = File.nameWithoutExtension;
			print("analysing: "+title1+"");
			getPixelSize(unit, pw, ph, pd);
			setTool("rectangle");
			waitForUser("please draw a rectangle for cropping");
			run("Crop");
			wait(100);
			setTool("line");
			waitForUser("please draw the calibration line (20MM)");
			run("Set Scale...", "known=20 unit=mm global");
			print("Scale = "+pw+" "+unit+" / pixel");
			run("Fill", "slice");
			run("Draw", "slice");
			setMinAndMax(0, 157);
			gridi=3;								//"start gridsize (to be adjusted)
			grida=(gridi*gridi);
			gridok=false;							// var for while loop of grid adjustemnt
			while(gridok==false){
				if(gridok==false){
					input=getNumber("set grid size in mm:", gridi);
					gridi=input;
					grida=(gridi*gridi);
					selectWindow(""+title1+"");
					run("Grid...", "grid="+GR+" area="+grida+" color=Cyan "+bd+" "+ra+"");
					getPixelSize(unit, pw, ph, pd);
					Dialog.create("Gridsize ok?");
					stepsG = newArray("Yes", "No, adjust");
					Dialog.addRadioButtonGroup("", stepsG, 2, 2,"Yes");
					Dialog.show;
					stepG=Dialog.getRadioButton;
					if(stepG=="Yes"){
						gridok=true;
						print("used gridsize: "+gridi+" "+unit+"");
					}
				}
			}
			enl=pw*2;
			run("RGB Color");								//for indicator color(s)
			run("Grid...", "grid="+GR+" area="+grida+" color=Cyan "+bd+" "+ra+"");
			Dialog.create("Controller");							//step controller
			steps = newArray("Analyse image", "Skip image");
			Dialog.addRadioButtonGroup("Next Step", steps, 2, 2, "Analyse image");
			Dialog.show;
			step=Dialog.getRadioButton;
			print("step: "+step+"");
			if(step=="Skip image"){
				print("skipping image "+title1+"");
				print("_");
				setForegroundColor(255, 0, 0);
				setFont("SansSerif", 40);
				drawString("SKIPPED", 500, 500);
				run("Flatten");
				saveAs("Jpeg", dir3+title2+"_skipped.jpg");
			}else{
				colr= newArray(255, 0, 100, 255, 180, 155, 255, 100, 70, 150, 160, 0); //can be adjusted as needed
				//colr= newArray("#ff4500","#51f242","#fdff01","#ff26eb","#00f9ff","#420420","#6777f6","#a43bff","#0c9400","#d20000");
				for (n=0; n<NS; n++) {
					No=No+1;
					N=N+1;
					selectWindow("Results");
					IJ.renameResults("ResOUT");
					run("Point Tool...", "type=Dot color=Magenta size=Medium show counter=0");
					setTool("multipoint");
					selectWindow(""+title1+"");
					run("Select None");
					waitForUser("Analysing "+title1+": click on points of desired object, then klick ok for next step");
					if(selectionType()!=-1){						//counting via number of point rois
						roiManager("Add");
						roiManager("Select", newArray());
						Roi.getCoordinates(x, y);
						Array.getStatistics(x, minx, maxx);
						Array.getStatistics(y, miny, maxy);
						roiManager("Measure");
						iObj=nResults;
						print("image "+title1+", "+iObj+" points");
						setForegroundColor(colr[No-1],colr[No],colr[No+1]);
						selectWindow(""+title1+"");
						roiManager("Select", newArray());	
						roiManager("Show All");
						roiManager("Deselect");
						roiManager("Combine");		
						run("Enlarge...", "enlarge="+enl+"");
						run("Fill", "slice");
						run("Draw", "slice");
						roiManager("Select", newArray());
						roiManager("delete");
						roiManager("reset");
						are=(iObj*gridi*gridi);					//area
						print("Area: "+are+" mm2");
						print("_");
						selectWindow("ResOUT");
						IJ.renameResults("Results");
						setResult("filename", nResults, actimage);
						setResult("grid in mm", nResults-1, gridi);
						setResult("points", nResults-1, iObj);
						setResult("Area [mm2]", nResults-1, are);
						updateResults();
					}else{
						No=No-1;
						N=N-1;
						selectWindow("ResOUT");
						IJ.renameResults("Results");
						setResult("filename", nResults, actimage);
						setResult("grid in mm", nResults-1, gridi);
						setResult("points", nResults-1, 0);
						setResult("Area [mm2]", nResults-1, 0);
						updateResults();
					}
				}
				//Image for QC:
				selectWindow(""+title1+"");
				saveAs("Jpeg", dir3+title2+"_measured.jpg");
				No=0;
			}
			while (nImages>0) {				
			selectImage(nImages);
			close();
			}
		}
		//reports/data:
		getDateAndTime(year, month, week, day, hour, min, sec, msec);
		print("Finished measuring of "+N+" Objects at: "+day+"/"+month+"/"+year+" :: "+hour+":"+min+":"+sec+"");
		selectWindow("Results");
		if(NS==1){
			saveAs("txt", ""+dir3+"Analysis_"+Sname+".xls");
		}else {
			saveAs("txt", ""+dir3+"Analysis_"+Sname+"_.xls");
		}
		selectWindow("Log");
		saveAs("Text", ""+dir3+"/log_analysis_"+day+"-"+month+"-"+year+"_"+hour+"h"+min+"min.txt");
		//cleaning up
		run("Clear Results");
		updateResults;
		showMessage("Report", ""+N+" objects measured - see output data in Destination Folder: "+dir2+"");
}
//Jens_15.12.21