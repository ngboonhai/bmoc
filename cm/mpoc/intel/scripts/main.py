
from argparse import ArgumentParser
from datetime import datetime
import sys
import os
import subprocess
import time
from shutil import copyfile

import parse_workload_config as wp
from parse_output import MLPerfParser


class MLPerfRunner():
	def __init__(self, config_file=""):
		self.config_file = config_file
		_time = datetime.now()
		self.timestamp = _time.strftime('%m-%d-%y-%H-%M-%S')
		self.output_csv =  os.path.basename(config_file).split(".")[0] + "-" + self.timestamp + ".csv"
	
	def getWorkloads(self):
		self.workloads, self._nruns, self._run_breaks = wp.parse_config(self.config_file)
		self.workload_cmds = wp.create_cmd_flags(self.workloads, write_commands=False)
		
	
	def runWorkloads(self):
		""" Run all processed workloads """

		APP = os.environ["OV_MLPERF_BIN"]
		append = False # Used to append results when writing parsed logs		
		num_wklds = self._nruns * len(self.workloads) # Total Number of workloads to run
		
		total_runs = 1
		for w_id, cmd_flag in self.workload_cmds.items():
			wkld = self.workloads[w_id] # Get associated workload config
			print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
			print("   RUNING WORKLOAD {}: {}, {}, precision={}, batch={}  \n".format(w_id, wkld["model_name"], wkld["scenario"], wkld["precision"], wkld["batch_size"] ))
			cmd = APP + " " + cmd_flag
			#print("{}".format(cmd))
			for iter in range(self._nruns):
				print("                      ~~ Run {} of {} ~~".format(iter+1, self._nruns))
			
				ret_code = subprocess.call(cmd, shell=True)
				if not ret_code:
					self.writeOutput(self.workloads[w_id], append)
				else:
					print("                      [ERROR]: Run failed")
					sys.exit(1)
					
				append = True
				if total_runs < num_wklds:
					print("                      ~~ Pause {}seconds before next run ~~\n".format(self._run_breaks))
					time.sleep(self._run_breaks)
			
				total_runs+= 1
	
	def writeOutput(self, workload_config, append=True):
		""" Parse mlperf output logs from application """
		
		results_parser = MLPerfParser(self.output_csv, "mlperf_log_summary.txt", "mlperf_log_detail.txt")
		output_dir = "Output" + self.timestamp
		if not os.path.exists(output_dir):
			os.mkdir(output_dir)
		dst_dir = output_dir + "/mlperf_log_summary" + "_" + workload_config["model_name"] + "_" + workload_config["scenario"] + "_Nireq-" + str(workload_config["nireq"]) +"_Nthreads-" + str(workload_config["nthreads"]) + "_" +  datetime.now().strftime('%m-%d-%y-%H-%M-%S') + ".txt"
		copyfile("mlperf_log_summary.txt", dst_dir)
		self.setParserAttributes(results_parser, workload_config)
		
		results_parser.parseMLPerfLogs(append)
		
		print(results_parser)
		
		tables_file = os.path.join("Results", self.output_csv + ".txt")
		open_mode = "a" if append else "w"
		with open(tables_file, open_mode) as fid:
			fid.writelines(results_parser.__str__())

		# Delete mlperf logs
		os.remove("mlperf_log_summary.txt")
		os.remove("mlperf_log_detail.txt")
		os.remove("mlperf_log_accuracy.json")
		os.remove("mlperf_log_trace.json")
	
	def setParserAttributes(self, results_parser, workload):
		results_parser.benchmark_scenario = workload["scenario"]
		results_parser.benchmark_model = workload["model_name"]
		results_parser.device_name = workload["device"]
		results_parser.precision = workload["precision"]
		results_parser.batch_size = str(workload["batch_size"])
		results_parser.instances = str(workload["nireq"])
		
		return results_parser

def main():
	parser = ArgumentParser()
	
	parser.add_argument('-c', '--config_file',
						type=str,
						default=os.path.join(os.environ["CONFIGS_DIR"], "default-config.json"),
						help="Path to configuration file"
						)
						
	args = parser.parse_args()
		
	if not os.path.isfile(args.config_file):
		print("Could not find config file {}".format(args.config_file))
		sys.exit(1)
		
	mlperf_runner = MLPerfRunner(args.config_file)
	mlperf_runner.getWorkloads()
	mlperf_runner.runWorkloads()
	print("Results saved in {}".format(os.path.join("Results", mlperf_runner.output_csv)))
	

if __name__=="__main__":
	main()
	
