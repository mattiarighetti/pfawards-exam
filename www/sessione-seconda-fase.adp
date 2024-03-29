<master>
  <property name="page_title">Sessione - PF</property>

  <if @target_date@ ne 0>
      <script language="JavaScript">
      TargetDate = "@target_date;noquote@";
      BackColor = "white";
      ForeColor = "black";
      CountActive = true;
      CountStepper = -1;
      LeadingZero = true;
      DisplayFormat = "%%M%% minuti e %%S%% secondi";
      FinishMessage = "Tempo finito!";
    </script>
  </if>
  
  <div class="container">
    <br>
      <center>
	<img class="center-block" style="display:inline-block;" height="150px" width="auto" src="http://images.professionefinanza.com/logos/pfawards.png">
      </center>
	  <div class="panel panel-default">
	    <div class="panel-body">
	      <p align="center">Stai svolgendo il questionario di @categoria;noquote@.</p>
	      <if @target_date@ ne 0>
		<center><p>Tempo rimasto a disposizione: <big><script language="JavaScript" src="http://scripts.hashemian.com/js/countdown.js"></script></big>.</p></center>
		  </if>
		  </div>
		</div>
	  <table class="table">
            <tr>
              <td>
		<p style="text-align:center;"><big>@domanda;noquote@</big></p>
            </td>
          </tr>
	</table>
	  <table class="table">
	    <tr>
	      <td align="left" width="100%">
		<formtemplate id="risposta"></formtemplate>
		</td>
	      </tr>
	      </table>
	  <center>
	    <a href="http://sso.professionefinanza.com/pfawards/" class="btn btn-primary" onClick="return(confirm('Sei sicuro di voler consegnare  il questionario? Potrai completarlo in un secondo momento, antecedente alla scadenza.'));"><span class="glyphicon glyphicon-open-file"></span> Chiudi</a>
	  </center>
      </div>
