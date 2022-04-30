# Import Modules
import os

os.system('pip install names')

import names
import random
from numpy.random import choice

def generateDOB(atRisk):
  dob = (random.choice(["01", "02", "03", "04", "05", "06", "07", "08", "09", 
    "10", "11", "12"]) + "/" + random.choice(["01", "02", "03", "04", "05", "06", 
    "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", 
    "20", "21", "22", "23", "24", "25", "26", "27", "28"]) + "/")
  if atRisk:
    dob += (random.choice(["1994", "1996", 
      "1997", "1998", "1999", "2000", "2001", "2002", "2003", "2004"]))
  else:
    dob += (random.choice(["1975","1976","1977","1978","1979","1980", "1981", "1982", "1983", "1984", "1985", "1986", 
    "1987", "1988", "1989", "1990", "1991", "1992", "1993", "1994", "1996", 
    "1997", "1998", "1999", "2000"]))
  return dob
  
def generateRace():
  race = ["hispanic", "white-not-hispanic", "black", "asian", "other"]
  return choice(race, 1, p=[0.60, 0.20, 0.10, 0.07, 0.03])

def generateSex(atRisk):
  if atRisk:
    return choice(["male", "female"], 1, p=[0.60, 0.40])
  else:
    return choice(["male", "female"], 1, p=[0.50, 0.50])

with open('contacts.csv', 'w') as contacts:
  contacts.write("contactID,firstName,middleName,lastName,DoB,race,sex,notes,isDeceased,isAtRisk,isActive\n")
  for i in range(50):
    firstName = names.get_first_name()
    middleName = names.get_first_name()
    lastName = names.get_last_name()
    race = generateRace()[0]
    if i < 20:
      dob = generateDOB(1)
      sex = generateSex(1)[0]
      isDeceased = 1 if i < 4 else 0
      if isDeceased:
        contacts.write(str(i) + "," + firstName + "," + middleName + "," + lastName + "," + dob + "," + race + "," + sex + "," + "" + "," + str(isDeceased) + "," + "1" + "," + "0" + "\n")
      else:
        contacts.write(str(i) + "," + firstName + "," + middleName + "," + lastName + "," + dob + "," + race + "," + sex + "," + "" + "," + str(isDeceased) + "," + "1" + "," + "1" + "\n")
    else:
      dob = generateDOB(0)
      sex = generateSex(0)[0]
      isDeceased = 1 if i < 22 else 0
      contacts.write(str(i) + "," + firstName + "," + middleName + "," + lastName + "," + dob + "," + race + "," + sex + "," + "" + "," + str(isDeceased) + "," + "0" + "," + "0" + "\n")


print('Program Ran Correctly...')