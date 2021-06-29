"""
Parser for MLPerf results. TAF~
"""

from argparse import ArgumentParser
import os
import sys
import csv
import time
import datetime

class MLPerfParser(object):

	def __init__(self, output_csv, summary_file, details_file=None, workload_flags=None, append=False):
		self.summary_file = summary_file
		self.details_file = details_file
		self.output_csv = output_csv
		self.workload_flags = workload_flags
		self.write_append = append
		self.resultsHeaders()
		self.getCommandFlags()
		

	def getCommandFlags(self):
		
		if self.workload_flags:
			with open(self.workload_flags, "r") as fid:
				flags = fid.read().splitlines()
				for line in flags:
					if "precision" in line:
						self.precision = line.split(" ")[-1]
					if "batch_size" in line:
						self.batch_size = line.split(" ")[-1]
					elif "device" in line:
						self.device_name = line.split(" ")[-1]
					elif "model_name" in line:
						self.benchmark_model = line.split(" ")[-1]
					elif "nireq" in line:
						self.instances = line.split(" ")[-1]
					elif "config_file" in line:
						self.output_csv = os.path.basename(line.split(": ")[-1]) + ".csv"
						
		
	def resultsHeaders(self):
		self.results_title = "MLPerf Benchmark Results"
		self.benchmark_scenario = "---"
		self.benchmark_model = "---"
		self.device_name = "---"
		self.benchmark_metrics = {"Single Stream": "90th %tile Latency", "Offline": "Throughput", "Server": "Completed QPS"}
		self.benchmark_val = "--"
		self.batch_size = "--"
		self.instances = "--"
		self.csv_headers = ["Total Samples processed", "Batch Size"]
		self.test_start = "---"
		self.test_end = "---"
		self.results_valid = "---" 
		self.precision = "---"


	def parseMLPerfDetail(self):
		if self.details_file:
			with open(self.details_file, 'r') as fid:
				lines = fid.read().splitlines()
			for line in lines:
				if "Scenario" in line:
					self.benchmark_scenario = line.split(": ")[-1]
					if (self.benchmark_scenario == "SingleStream" or self.benchmark_scenario == "Single Stream"):
						self.benchmark_scenario = "Single Stream"
				if "POWER_BEGIN" in line:
					self.test_start = line.split(" ")[-1]
				if "POWER_END" in line:
					self.test_end = line.split(" ")[-1]
				if "*" in line:
					self.Recommendations = line

	def parseMLPerfSummary(self):
		if self.summary_file:
			with open(self.summary_file, 'r') as fid:
				lines = fid.read().splitlines()
			for line in lines:
				if "Scenario" in line:
					self.benchmark_scenario = line.split(": ")[-1]
				elif "VALID" in line:
					self.results_valid = line.split(": ")[-1]
				elif "90th percentile" in line:
					self.benchmark_val = str(round(int(line.split(": ")[-1])/1000000, 2)) + " ms"
				elif "Completed samples per second" in line:
					self.benchmark_val = line.split(": ")[-1] + " fps"
				elif "Samples per" in line:
					self.benchmark_val = line.split(": ")[-1] + " fps"


	def parseMLPerfLogs(self, append=False):

		self.parseMLPerfDetail()
		self.parseMLPerfSummary()
		self.writeToOutput(append)
		return

	def writeToOutput(self, append=False):
		fieldnames = ["Model", 
					"Scenario",
					"Precision",
					"Device",
					"Batch Size",
					"Instances",
					"Performance", 
					"Results Validity", 
					"TEST START", 
					"TEST END"
					]
		
		os.makedirs("Results", exist_ok=True)
		output_path = os.path.join("Results",self.output_csv)
		open_mode = "a" if append else "w"
		
		with open(output_path, open_mode) as csv_file:
			writer = csv.DictWriter(csv_file, fieldnames=fieldnames);
			if not append:
				writer.writeheader()
				
			writer.writerow({"Model": self.benchmark_model, 
							"Scenario": self.benchmark_scenario,
							"Precision": self.precision,
							"Device": self.device_name, 
							"Batch Size": self.batch_size,
							"Instances": self.instances,
							"Performance": self.benchmark_val,
							"Results Validity": self.results_valid, 
							"TEST START": self.test_start, 
							"TEST END": self.test_end,
							}
							)
		return

	def __str__(self):

		table_width = len(self.results_title) + 40  # Table width
		table_shift = 4                             # Shift entire table
		val_loc = int(table_width/2)                # where to put values
		key_loc = 3                                 # how many spaces from left

		def topBottom(corner="*",bnd="=", shift=1):
			res = "".join(ch for ch in [" "]*table_shift) + corner + "".join(ch for ch in ["="]*table_width) + corner + "\n"

			return res

		def writeTitle(title_name, shift=1):
			head_spaces_1 = int(0.5*(table_width - len(title_name)))
			head_spaces_2 = table_width - head_spaces_1 - len(title_name)
		
			out = "".join(ch for ch in [" "]*shift) + "|" + "".join(ch for ch in [" "]*head_spaces_1)
			out+= title_name

			out = out + "".join(ch for ch in [" "]*head_spaces_2) + "|\n"
			out = out + skipRows(1, char=" ", shift=shift)
			out = out + skipRows(1, char="~", shift=shift)

			return out

		def skipRows(numRows=2, char = " ", shift=1):
			out = ""
			for i in range(numRows):
				out = out + "".join(ch for ch in [" "]*shift) + "|" + "".join(ch for ch in [char]*table_width ) + "|\n"

			return out

		def writeRow(row_name, row_val, shift=1):

			row = "|" + "".join(ch for ch in [" "]*key_loc) + row_name 
			key_val = row + ":" + "".join(ch for ch in [" "]*(val_loc - len(row))) + row_val
			left_spc = table_width - len(key_val) + 1
			out = key_val + "".join(ch for ch in [" "]*left_spc) + "|\n"

			return "".join(ch for ch in [" "]*shift) + out

		# Create Header
		res = topBottom(corner="@", bnd = "=", shift=table_shift)

		res = res + skipRows(numRows=2, char=" ", shift = table_shift)
		
		# put title
		res = res + writeTitle(self.results_title, shift = table_shift)

		# Add Model
		res = res + writeRow("Model", self.benchmark_model, shift=table_shift)

		#  Add Scenario
		res = res + writeRow("Scenario", self.benchmark_scenario, shift = table_shift)

		# Add SUT
		res = res + writeRow("Device", self.device_name, shift = table_shift)
		
		# Add Metric
		res = res + writeRow(self.benchmark_metrics[self.benchmark_scenario], self.benchmark_val, shift = table_shift)

		# Add result validity
		res = res + writeRow("Results Validity", self.results_valid, shift=table_shift)

		# Add runtime
		#res = res + skipRows(numRows=1, char="-", shift=table_shift)       
		res = res + writeRow("TEST START", self.test_start, shift = table_shift)
		res = res + writeRow("TEST END", self.test_end, shift = table_shift)

		# Add Benchmark parameters
		res = res + skipRows(numRows=1, char="-", shift=table_shift)
		res = res + skipRows(numRows=1, char=" ", shift=table_shift)
		res = res + writeTitle("Benchmark Parameters", shift=table_shift)

		# Add Precision
		res = res + writeRow("Precision", self.precision, shift=table_shift)
		# Add Batch size
		res = res + writeRow("Batch Size", self.batch_size, shift=table_shift)
		
		# Add no. instances
		res = res + writeRow("Instances", self.instances, shift=table_shift)
		
		# Add ...<whatever-of-interest>...
		if self.results_valid = "INVALID":
			res = res + writeRow("Recommendations", self.Recommendations, shift=table_shift)
		# Close bottom
		res = res + topBottom(corner="@", bnd = "=", shift=table_shift)

		return res



def get_args():
	parser = ArgumentParser()

	parser.add_argument("-s", "--summary_file", type=str, required=True, help="MLPerf Summary Results file to be parsed.")
	parser.add_argument("-d", "--details_file", type=str, help="MLPerf log details file.")
	parser.add_argument("-o", "--output", type=str, help="csv output filename to save results to.")
	parser.add_argument("-f", "--flags_file", type=str, help="txt file containing input flags and values used for running the workloads whose output we're parsing.\nThis is usually produced when the workload parser is called.")
	parser.add_argument("-a", "--append", action="store_true", dest="write_append", help="Overwrite the existing csv or append to")

	return parser.parse_args()


def main():
	output_csv = "mlperf-summary.csv"
	details_file = None
	workload_flags_file = None
	
	args = get_args()
	if not args.summary_file:
		return

	summary_file=args.summary_file
	if args.output:
		output_csv = args.output
		
	if args.details_file:
		details_file=args.details_file
		
	if args.flags_file:
		workload_flags_file = args.flags_file
		

	res_parser = MLPerfParser(output_csv, summary_file, details_file, workload_flags_file,args.write_append)
	res_parser.parseMLPerfLogs(args.write_append)
	
	print(res_parser)
	open_mode = "a" if res_parser.write_append else "w"
	with open("Results/tables.txt", open_mode) as fid:
		fid.writelines(res_parser.__str__())


if __name__=="__main__":
	main()
