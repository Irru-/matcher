function isNumberKey(evt) {

				 var charCode = (evt.which) ? evt.which : event.keyCode
				 if (charCode > 31 && (charCode < 48 || charCode > 57))
					return false;
		 
				 return true;
			  }
				
function isNumberKeyLoc(evt) {
				
				 var charCode = (evt.which) ? evt.which : event.keyCode
				 if (charCode > 31 && (charCode < 48 || charCode > 57))
					return false;
		 
				 return true;
			  }
				
				
function notEmpty(afstand, locatie, skill, edu, helperMsg) {
	
			var volg = true;

				var afstand = document.getElementById(afstand);
				if (!afstand.value.length) {
						alert(helperMsg);
						afstand.focus();
						return false;
				}

				var locatie = document.getElementById(locatie);
				if (!locatie.value.length) {
						alert(helperMsg);
						locatie.focus();
						return false;
				}
				
				var skill = document.getElementById(skill);
				if (!skill.value.length) {
						alert(helperMsg);
						skill.focus();
						return false;
				}
				
				var edu = document.getElementById(edu);
				if (!edu.value.length) {
						alert(helperMsg);
						edu.focus();
						return false;
				}

		return volg;
			}