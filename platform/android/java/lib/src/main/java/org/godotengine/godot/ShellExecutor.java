package org.godotengine.godot;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

public final class ShellExecutor {
	private ShellExecutor() {
	}

	/**
	 * Executes a command through bash and returns combined stdout/stderr.
	 *
	 * This method is intended for the Android editor's headless command runner.
	 * The caller is responsible for invoking it off the main/UI thread when the
	 * command may take a significant amount of time.
	 */
	public static String execute_command(String command) {
		if (command == null) {
			return "Error: command is null";
		}

		try {
			Process process = new ProcessBuilder("bash", "-c", command)
					.redirectErrorStream(true)
					.start();

			StringBuilder output = new StringBuilder();
			try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
				String line;
				while ((line = reader.readLine()) != null) {
					output.append(line).append('\n');
				}
			}

			int exitCode = process.waitFor();
			if (exitCode != 0) {
				output.append("Process exited with code ").append(exitCode).append('\n');
			}

			return output.toString().trim();
		} catch (IOException e) {
			return "Error starting bash: " + e.getMessage();
		} catch (InterruptedException e) {
			Thread.currentThread().interrupt();
			return "Error: command interrupted";
		}
	}
}
