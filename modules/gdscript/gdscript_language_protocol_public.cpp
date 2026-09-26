/**************************************************************************/
/*  gdscript_language_protocol_public.cpp                               */
/**************************************************************************/
/*                         This file is part of:                          */
/*                             GODOT ENGINE                               */
/*                        https://godotengine.org                         */
/**************************************************************************/
/* Copyright 2026 (c) Alamin, All contributor and creators.              */
/* Copyright (c) 2014-present Godot Engine contributors (see AUTHORS.md). */
/* Copyright (c) 2007-2014 Juan Linietsky, Ariel Manzur.                  */
/*                                                                        */
/* Permission is hereby granted, free of charge, to any person obtaining  */
/* a copy of this software and associated documentation files (the        */
/* "Software"), to deal in the Software without restriction, including    */
/* without limitation the rights to use, copy, modify, merge, publish,    */
/* distribute, sublicense, and/or sell copies of the Software, and to     */
/* permit persons to whom the Software is furnished to do so, subject to   */
/* the following conditions:                                              */
/*                                                                        */
/* The above copyright notice and this permission notice shall be         */
/* included in all copies or substantial portions of the Software.        */
/*                                                                        */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,        */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF     */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. */
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY   */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,   */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE      */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                 */
/**************************************************************************/
#include "gdscript_language_protocol_public.h"

#ifdef TOOLS_ENABLED

#include "core/extension/extension_api_dump.h"
#include "core/io/file_access.h"
#include "core/io/json.h"

void GDScriptLanguageAPI::_bind_methods() {
	ClassDB::bind_method(D_METHOD("get_extension_apis"), &GDScriptLanguageAPI::get_extension_apis);
	ClassDB::bind_method(D_METHOD("read_extension_apis", "path"), &GDScriptLanguageAPI::read_extension_apis);
	ClassDB::bind_method(D_METHOD("save_extension_apis", "path"), &GDScriptLanguageAPI::save_extension_apis);
}

Dictionary GDScriptLanguageAPI::get_extension_apis() {
	return GDExtensionAPIDump::generate_extension_api();
}

Dictionary GDScriptLanguageAPI::read_extension_apis(const String &p_path) {
	Error error = OK;
	String text = FileAccess::get_file_as_string(p_path, &error);
	if (error != OK) {
		ERR_PRINT(vformat("GDScriptLanguageAPI: Could not open API dump '%s'.", p_path));
		return Dictionary();
	}

	Ref<JSON> json;
	json.instantiate();
	error = json->parse(text);
	if (error != OK) {
		ERR_PRINT(vformat("GDScriptLanguageAPI: Error parsing '%s' at line %d: %s", p_path, json->get_error_line(), json->get_error_message()));
		return Dictionary();
	}

	Variant data = json->get_data();
	if (data.get_type() != Variant::DICTIONARY) {
		ERR_PRINT(vformat("GDScriptLanguageAPI: API dump '%s' does not contain a Dictionary.", p_path));
		return Dictionary();
	}

	return data;
}

Error GDScriptLanguageAPI::save_extension_apis(const String &p_path) {
	Ref<FileAccess> file = FileAccess::open(p_path, FileAccess::WRITE);
	if (file.is_null()) {
		return FileAccess::get_open_error();
	}
	file.unref();

	GDExtensionAPIDump::generate_extension_json_file(p_path);

	Error error = OK;
	String text = FileAccess::get_file_as_string(p_path, &error);
	if (error != OK) {
		ERR_PRINT(vformat("GDScriptLanguageAPI: Could not read generated API dump '%s'.", p_path));
		return error;
	}

	Ref<JSON> json;
	json.instantiate();
	error = json->parse(text);
	if (error != OK) {
		ERR_PRINT(vformat("GDScriptLanguageAPI: Generated API dump '%s' is invalid JSON at line %d: %s", p_path, json->get_error_line(), json->get_error_message()));
		return error;
	}

	if (json->get_data().get_type() != Variant::DICTIONARY) {
		ERR_PRINT(vformat("GDScriptLanguageAPI: Generated API dump '%s' is not a Dictionary.", p_path));
		return ERR_INVALID_DATA;
	}

	return OK;
}

#endif // TOOLS_ENABLED
