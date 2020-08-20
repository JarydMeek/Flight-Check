//http://www.usahas.com/webservices/AHAS.asmx/GetAHASRisk12?Area=%27SHEPPARD%20AFB%20WICHITA%20FALLS%20MUNI%27&iMonth=8&iDay=20&iHour=6

#include<iostream>
#include<fstream>

using namespace std;

int main() {
    string myText[2];
    string raw;
    ifstream Input("./icaoToNameAHAS.txt");

    int counter = 0;
    while (getline (Input, raw)) {
        myText[counter] = raw;
        counter++;
    }

    int currentSave = 0;
    string currentICAO;
    string currentNAME;
    string savedICAO[1000];
    string savedNAME[1000];
    for(int i = 0; i < myText[0].length(); i++) {
        if (myText[0][i] != '*'){
            currentICAO = currentICAO + myText[0][i];
        } else {
            savedICAO[currentSave] = currentICAO;
            currentICAO = "";
            currentSave++;
        }
    }
    int currentSave2 = 0;
    for(int i = 0; i < myText[1].length(); i++) {
        if (myText[1][i] != '*'){
            if (myText[1][i] == ',') {
                currentNAME = currentNAME + " - ";
            } else {
                currentNAME = currentNAME + myText[1][i];
            }
        } else {
            savedNAME[currentSave2] = currentNAME;
            currentNAME = "";
            currentSave2++;
        }
    }

    ofstream output("output.csv");

    int outputCounter = 0;
    while (savedICAO[outputCounter] != "") {
        cout << savedICAO[outputCounter] + "," + savedNAME[outputCounter] << endl;
        output << savedICAO[outputCounter] + "," + savedNAME[outputCounter] << endl;
        outputCounter++;
    }
    output.close();
}