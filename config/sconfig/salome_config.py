#  -*- coding: iso-8859-1 -*-

"""
Manage SALOME configuration.

Typical usage:

tool = CfgTool()
# Create configuration and set its parameters
tool.set("cfg", "name", "V7_6_0", "comment", "SALOME version 7.6.0")
# Add product
tool.set("boost", "version", "1.52.2", "url", "https://sourceforge.net/projects/boost/files/boost/1.52.0/boost_1_52_0.tar.gz", "comment", "Set of libraries for the C++ programming language")
# Add patches to the product (note: patch file should  be manually put to the patches directory)
tool.set("boost.patches.boost_patch_1.patch", "comment", "Fixes compilation problems on some platforms")
tool.set("boost.patches.boost_patch_2.patch", "comment", "gcc 5 compatibility")
# Inspect configuration: give all products
tool.get("cfg", "products")
# Inspect configuration: give parameters of the configuration
tool.get("cfg", "name")
tool.get("cfg", "comment")
# Inspect configuration: give parameters of the product
tool.get("boost", "version")
tool.get("boost", "url")
# Inspect configuration: give patches for the product
tool.get("boost", "patches")
# Verify configuration
conf_ok = tool.verify()
# Verify product
boost_ok = tool.verify("boost")
# Dump configuration
tool.dump()
# Dump product
tool.dump("boost")
# Remove parameters of configuration
tool.remove("cfg", "comment")
# Remove parameters of product
tool.remove("boost", "url")
# Remove patch from product
tool.remove("boost.patches.boost_patch_2.patch")
# Remove product
tool.remove("boost")
# Clean configuration
tool.clean()
"""

import os
import xml.etree.ElementTree as ET
try:
    exceptionClass = ET.ParseError
except:
    import xml.parsers.expat
    exceptionClass = xml.parsers.expat.ExpatError

__all__ = [
    "defaultConfFile",
    "configTag",
    "softwareTag",
    "patchesTag",
    "patchTag",
    "nameAttr",
    "commentAttr",
    "versionAttr",
    "urlAttr",
    "supportedTags",
    "supportedAttributes",
    "tagAttributes",
    "tagChildren",
    "softwareAlias",
    "patchesAlias",
    "childAlias",
    "pathSeparator",
    "CfgTool",
 ]

def defaultConfFile():
    """
    Return path to the default SALOME configuration file (string).
    """
    return os.path.realpath(os.path.join(os.path.dirname(__file__), "..", "salome.xml"))

def configTag():
    """
    Return XML tag for configuration (string).
    """
    return "config"

def softwareTag():
    """
    Return XML tag for software (string).
    """
    return "product"

def patchesTag():
    """
    Return XML tag for patches set (string).
    """
    return "patches"
    
def patchTag():
    """
    Return XML tag for patch (string).
    """
    return "patch"

def nameAttr():
    """
    Return XML attribute for name parameter (string).
    """
    return "name"

def commentAttr():
    """
    Return XML attribute for comment parameter (string).
    """
    return "comment"

def versionAttr():
    """
    Return XML attribute for version parameter (string).
    """
    return "version"

def urlAttr():
    """
    Return XML attribute for url parameter (string).
    """
    return "url"

def supportedTags():
    """
    Return list of all supported XML tags (list of strings).
    """
    return [configTag(), softwareTag(), patchesTag(), patchTag()]
    
def supportedAttributes():
    """
    Return list of all supported XML attributes (list of strings).
    """
    return [nameAttr(), commentAttr(), versionAttr(), urlAttr()]
    
def tagAttributes(tag, force = False):
    """
    Return list of attributes supported for the specified XML tag.
    
    Parameters:
      tag: XML tag.
      force: if True, all supported attributes are returned, including "special" ones.

    Return value is list of strings.
    """
    attrs = {}
    if tag == configTag():
        # config
        attrs[nameAttr()]     = False  # optional
        attrs[commentAttr()]  = False  # optional
        pass
    elif tag == softwareTag():
        # software
        # note: name for software is specified implicitly via the target path
        if force:
            attrs[nameAttr()] = True   # mandatory
            pass
        attrs[versionAttr()]  = True   # mandatory
        attrs[urlAttr()]      = False  # optional
        attrs[commentAttr()]  = False  # optional
        pass
    elif tag == patchTag():
        # patch
        # note: name for patch is specified implicitly via the target path
        if force:
            attrs[nameAttr()] = True   # mandatory
            pass
        pass
        attrs[urlAttr()]      = False
        attrs[commentAttr()]  = False
    return attrs

def tagChildren(tag):
    """
    Return supported child nodes' tags for given XML element.
    Note: None means root 'config' XML element.
    
    Parameters:
      tag: XML tag.

    Return value is list of strings.
    """
    ctags = []
    if tag == configTag():     ctags += [softwareTag()]
    elif tag == softwareTag(): ctags += [patchesTag()]
    elif tag == patchesTag():  ctags += [patchTag()]
    elif tag is None:          ctags += [configTag()]
    return ctags

def softwareAlias():
    """
    Return parameter's alias for list of software are to be used with 'get' command (string).
    """
    return softwareTag()+"s"

def patchesAlias():
    """
    Return parameter's alias for list patches to be used with 'get' command (string).
    """
    return patchesTag()

def childAlias(tag, param):
    """
    Return children node tag for children list alias.
    
    Parameters:
      tag: XML tag.
      param: children list alias.

    Return child node tag name or None if alias is unsupported.
    """
    ctag = None
    if tag == configTag():
        if param == softwareAlias(): ctag = softwareTag()
        pass
    elif tag == softwareTag():
        if param == patchesAlias(): ctag = patchTag()
        pass
    return ctag

def pathSeparator():
    """
    Return string used as a separator of path's component (string).
    """
    return "."

class CfgTool(object):
    """
    A tool to manage SALOME configuration files.
    """
    def __init__(self, cfgFile=None):
        """
        Constructor.
        
        Parameters:
          cfgFile: a path to the configuration file (string);
                   if not specified, default one is used.
        """
        self.enc = "utf-8"
        self.cfgFile = cfgFile if cfgFile else defaultConfFile()
        try:
            self.tree = ET.parse(self.cfgFile).getroot()
            self._checkConfig()
            pass
        except IOError, e:
            self.tree = self._new()
            pass
        except exceptionClass, e:
            if e.code == 3: # no element found, it's OK
                self.tree = self._new()
            else:
                raise Exception("bad XML file %s: %s" % (self.cfgFile, str(e)))
            pass
        except Exception, e:
            raise Exception("unkwnown error: %s" % str(e))
        pass
    
    def encoding(self):
        """
        Return current encoding of the configuration file (string).
        Default is "utf-8".
        """
        return self.enc
    
    def setEncoding(self, value):
        """
        Set encoding for configuration file..
        Parameters:
          value: new encoding to be used when writing configuration file (string).
        """
        self.enc = value
        self._write()
        pass

    def get(self, target, param):
        """
        Get value of specified object's parameter.
        Parameter can be a specific keyword that refers to the list of
        child nodes. In this case the function returns list that
        contains names of all child nodes.

        Parameters:
          target: object being checked (string).
          param: parameter which value is being inspected.
         
        Return value is string or list of strings.
        """
        path = self._processTarget(target)
        tag = path[-1][0]
        elem = self._findPath(path)
        if elem is None:
            raise Exception("no such target %s" % target)
        result = None
        if childAlias(tag, param):
            result = self._children(elem, childAlias(tag, param))
            pass
        elif param in tagAttributes(tag):
            result = elem.get(param) if elem is not None and elem.get(param) else ""
            pass
        else:
            raise Exception("unsupported parameter %s for target %s" % (param, target))
        return result

    def set(self, target = None, *args, **kwargs):
        """
        Create or modify an object in the SALOME configuration.

        Parameters:
          target: object being created or modified (string); if not specified,
                  parameters of config itself will be modified.
          args:   positional arguments that describe parameters to be set (couple);
                  each couple of arguments specifies a parameter and its value
                  (strings).
          kwargs: keyword arguments - same as 'args' but specified in form of
                  dictionary.
        """
        path = self._processTarget(target)
        tag = path[-1][0]
        params = {}
        # process keyword arguments
        for param, value in kwargs.items():
            if param not in tagAttributes(tag):
                raise Exception("unsupported parameter %s for target %s" % (param, target))
            params[param] = value
            pass
        # process positional arguments
        i = 0
        while i < len(args):
            param = args[i]
            if param not in tagAttributes(tag):
                raise Exception("unsupported parameter %s for target %s" % (param, target))
            value = ""
            if i+1 < len(args) and args[i+1] not in tagAttributes(tag):
                value = args[i+1]
                i += 1
                pass
            params[param] = value
            i += 1
            pass
        # create / modify target
        elem = self._findPath(path, True)
        for param, value in params.items():
            elem.set(param, value)
            pass
        self._write()
        pass

    def remove(self, target, *args):
        """
        Remove object or its parameter(s).

        Parameters:
          target: object (string).
          args: list of parameters which have to be removed (strings).
         
        Return value is string.
        """
        path = self._processTarget(target)
        tag = path[-1][0]
        elem = self._findPath(path)
        if elem is None:
            raise Exception("no such target %s" % target)
        if args:
            # remove attributes of the target
            # first check that all attributes are valid
            for param in args:
                if param not in tagAttributes(tag):
                    raise Exception("unsupported parameter %s for target %s" % (param, target))
                elif param not in elem.attrib:
                    raise Exception("parameter %s is not set for target %s" % (param, target))
                pass
            # now remove all attributes
            for param in args:
                elem.attrib.pop(param)
                pass
            pass
        else:
            # remove target
            if elem == self.tree:
                self.tree = self._new()
                pass
            else:
                path = path[:-1]
                parent = self._findPath(path)
                if parent is not None: parent.remove(elem)
                pass
            pass
        self._write()
        pass
    
    def dump(self, target = None):
        """
        Dump the configuration.
        
        Parameters:
          target: object (string); if not specified, all configuration is dumped.
        """
        if target is not None:
            path = self._processTarget(target)
            elem = self._findPath(path)
            if elem is None:
                raise Exception("no such target %s" % target)
            pass
        else:
            elem = self.tree
            pass
        self._dump(elem)
        pass

    def verify(self, target = None, errors = None):
        """
        Verify configuration
        
        Parameters:
          target: object (string); if not specified, all configuration is verified.

        Returns True if object is valid or False otherwise.
        """
        if errors is None: errors = []
        if target is not None:
            path = self._processTarget(target)
            elem = self._findPath(path)
            if elem is None:
                raise Exception("no such target %s" % target)
            pass
        else:
            elem = self.tree
            pass
        return self._verifyTag(elem, errors)

    def clean(self):
        """
        Clean the configuration.
        """
        self.tree = self._new()
        self._write()
        pass
    
    def patchesDir(self):
        """
        Return path to the patches directory (string).
        """
        return os.path.join(os.path.dirname(self.cfgFile), "patches")

    def _new(self):
        """
        (internal)
        Create and return new empty root element.
        
        Return values is an XML element (xml.etree.ElementTree.Element).
        """
        return ET.Element(configTag())

    def _makeChild(self, elem, tag):
        """
        (internal)
        Create child element for given parent element.

        Parameters:
          elem: XML element (xml.etree.ElementTree.Element).
          tag: tag of the child element

        Return value is new XML element (xml.etree.ElementTree.Element).
        """
        child = ET.SubElement(elem, tag)
        child._parent = elem # set parent!!!
        return child

    def _processTarget(self, target):
        """
        (internal)
        Check target and return XML path for it.

        Parameters:
          target: target path.
          
        Return value is a list of tuples; each tuple is a couple
        of path component and optional component's name.
        """
        if target is None: target = ""
        comps = [i.strip() for i in target.split(pathSeparator())]
        path = []
        # add root to the path
        path.append((configTag(), None))
        if comps[0] in ["", "cfg", configTag()]: comps = comps[1:]
        if comps:
            # second component of path can be only "software"
            if not comps[0] or comps[0] in supportedTags() + supportedAttributes() + ["cfg"]:
                raise Exception("badly specified target '%s'" % target)
            path.append((softwareTag(), comps[0]))
            comps = comps[1:]
            pass
        if comps:
            # third component of path can be only "patches" or patch
            if comps[0] not in [patchesTag(), patchTag()]:
                raise Exception("badly specified target '%s'" % target)
            path.append((patchesTag(), None))
            comps = comps[1:]
            pass
        if comps:
            # fourth component of path can be only a patch name
            path.append((patchTag(), pathSeparator().join(comps)))
            pass
        return path
    
    def _findPath(self, path, create=False):
        """
        (internal)
        Find and return XML element specified by its path.
        If path does not exist and 'create' is True, XML element will be created.

        Parameters:
          path: XML element's path data (see _processTarget()).
          create: flag that forces creating XML element if it does not exist
                  (default is False).

        Return value is an XML element (xml.etree.ElementTree.Element).
        """
        if len(path) == 1:
            if path[0][0] != configTag():
                raise Exception("error parsing target path")
            return self.tree
        elem = self.tree
        for tag, name in path[1:]:
            if name:
                children = filter(lambda i: i.tag == tag and i.get(nameAttr()) == name, elem.getchildren())
                if len(children) > 1:
                    raise Exception("error parsing target path: more than one child element found")
                elif len(children) == 1:
                    elem = children[0]
                    pass
                elif create:
                    elem = self._makeChild(elem, tag)
                    elem.set(nameAttr(), name)
                    pass
                else:
                    return None
                pass
            else:
                children = filter(lambda i: i.tag == tag, elem.getchildren())
                if len(children) > 1:
                    raise Exception("error parsing target path: more than one child element found")
                elif len(children) == 1:
                    elem = children[0]
                    pass
                elif create:
                    elem = self._makeChild(elem, tag)
                    pass
                else:
                    return None
                pass
            pass
        return elem

    def _path(self, elem):
        """
        (internal)
        Construct path to the XML element.

        Parameters:
          elem: XML element (xml.etree.ElementTree.Element).

        Return value is string.
        """
        def _mkname(_obj):
            _name = _obj.tag
            attrs = tagAttributes(_obj.tag, True)
            if nameAttr() in attrs and attrs[nameAttr()]:
                if nameAttr() not in _obj.keys(): _name += " [unnamed]"
                else: _name += " [%s]" % _obj.get(nameAttr())
                pass
            return _name
        path = []
        while elem is not None:
            path.append(_mkname(elem))
            elem = elem._parent if hasattr(elem, "_parent") else None
            pass
        path.reverse()
        return pathSeparator().join(path)

    def _children(self, elem, param):
        """
        (internal)
        Get names of children nodes for element.

        Parameters:
          elem: XML element (xml.etree.ElementTree.Element).
          param: name of the children' tag.

        Return value is a list of names of child elements (strings).
        """
        result = []
        result += [i.get(nameAttr()) for i in \
                       filter(lambda i: i.tag == param and i.get(nameAttr()), elem.getchildren())]
        for c in elem.getchildren():
            result += self._children(c, param)
            pass
        return result
        
    def _write(self):
        """
        (internal)
        Write data tree content to the associated XML file.
        """
        try:
            with open(self.cfgFile, 'w') as f:
                # write header
                f.write('<?xml version="1.0" encoding="%s" ?>\n' % self.encoding() )
                f.write('<!DOCTYPE config>\n')
                # prettify content
                self._prettify(self.tree)
                # write content
                et = ET.ElementTree(self.tree)
                et.write(f, self.encoding())
                pass
            pass
        except IOError, e:
            raise Exception("can't write to %s: %s" % (self.cfgFile, e.strerror))
        pass

    def _prettify(self, elem, level=0, hasSiblings=False):
        """
        (internal)
        Prettify XML file content.

        Parameters:
          elem: XML element (xml.etree.ElementTree.Element).
          level: indentation level.
          hasSiblings: True when item has siblings (i.e. this is not the last item
             in the parent's children list).
        """
        indent = "  "
        children = elem.getchildren()
        tail = "\n"
        if hasSiblings: tail += indent * level
        elif level > 0: tail += indent * (level-1)
        text = None
        if children: text = "\n" + indent * (level+1)
        elem.tail = tail
        elem.text = text
        for i in range(len(children)):
            self._prettify(children[i], level+1, len(children)>1 and i+1<len(children))
            pass
        pass

    def _dump(self, elem, level=0):
        """
        (internal)
        Dump XML element.

        Parameters:
          elem: XML element (xml.etree.ElementTree.Element).
          level: indentation level.
        """
        if elem is None:
            return
        indent = "  "
        # dump element
        print "%s%s" % (indent * level, elem.tag)
        attrs = tagAttributes(elem.tag, True)
        format = "%" + "-%ds" % max([len(i) for i in supportedAttributes()]) + " : %s"
        for a in attrs:
            if a in elem.attrib.keys():
                print indent*(level+1) + format % (a, elem.get(a))
                pass
            pass
        print
        # dump all childrens recursively
        for c in elem.getchildren():
            self._dump(c, level+1)
            pass
        pass

    def _checkConfig(self):
        """
        (internal)
        Verify configuration (used to check validity of associated XML file).
        """
        errors = []
        self._checkTag(self.tree, None, errors)
        if errors:
            errors = ["Bad XML format:"] + ["- %s" % i for i in errors]
            raise Exception("\n".join(errors))
        pass

    def _checkTag(self, elem, tag, errors):
        """
        (internal)
        Check if format of given XML element is valid.
        
        Parameters:
          elem: XML element (xml.etree.ElementTree.Element).
          tag: expected XML element's tag (string).
          errors: output list to collect error messages (strings).
        """
        if elem.tag not in tagChildren(tag):
            errors.append("bad XML element: %s" % elem.tag)
        else:
            # check attributes
            attrs = elem.keys()
            for attr in attrs:
                if attr not in tagAttributes(elem.tag, True):
                    errors.append("unsupported attribute '%s' for XML element '%s'" % (attr, elem.tag))
                    pass
                pass
            # check all childrens recursively
            children = elem.getchildren()
            for child in children:
                child._parent = elem # set parent!!!
                self._checkTag(child, elem.tag, errors)
                pass
            pass
        pass

    def _verifyTag(self, elem, errors):
        """
        (internal)
        Verify given XML element is valid in terms of SALOME configuration.
        
        Parameters:
          elem: XML element (xml.etree.ElementTree.Element).
          errors: output list to collect error messages (strings).
        """
        attrs = tagAttributes(elem.tag, True)
        # check mandatory attributes
        for attr in attrs:
            if attrs[attr] and (attr not in elem.keys() or not elem.get(attr).strip()):
                errors.append("mandatory parameter '%s' of object '%s' is not set" % (attr, self._path(elem)))
                pass
            pass
        # specific check for particular XML element
        try:
            self._checkObject(elem)
        except Exception, e:
            errors.append("%s : %s" % (self._path(elem), str(e)))
        # check all childrens recursively
        for c in elem.getchildren():
            self._verifyTag(c, errors)
            pass
        return len(errors) == 0

    def _checkObject(self, elem):
        """
        (internal)
        Perform specific check for given XML element.
        
        Raises an exception that if object is invalid.
        
        Parameters:
          elem: XML element (xml.etree.ElementTree.Element).
        """
        if elem.tag == patchTag():
            filename = elem.get(nameAttr())
            url = elem.get(urlAttr())
            if filename and not url:
                # if url is not given, we should check that file is present locally
                filepath = os.path.join(self.patchesDir(), filename)
                if not os.path.exists(filepath):
                    raise Exception("patch file %s is not found" % filepath)
                pass
            else:
                # TODO: we might check validity of URL here (see urlparse)!
                pass
            pass
        pass

    pass # class CfgTool
