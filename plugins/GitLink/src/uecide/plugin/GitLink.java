package uecide.plugin;

import uecide.app.*;
import uecide.app.debug.*;
import uecide.app.editors.*;
import java.io.*;
import java.util.*;
import java.net.*;
import java.util.zip.*;
import java.util.regex.*;
import javax.swing.*;
import javax.swing.border.*;
import javax.swing.event.*;
import javax.swing.text.*;
import javax.swing.table.*;
import javax.swing.tree.*;
import java.awt.*;
import java.awt.event.*;
import say.swing.*;
import org.json.simple.*;
import java.beans.*;
import java.util.List;

import org.eclipse.jgit.api.*;
import org.eclipse.jgit.api.errors.*;
import org.eclipse.jgit.api.CreateBranchCommand.SetupUpstreamMode;
import org.eclipse.jgit.lib.StoredConfig;
import org.eclipse.jgit.lib.Config;
import org.eclipse.jgit.lib.Repository;
import org.eclipse.jgit.storage.file.*;
import org.eclipse.jgit.internal.storage.file.*;
import org.eclipse.jgit.treewalk.TreeWalk;
import org.eclipse.jgit.revwalk.RevCommit;
import org.eclipse.jgit.revwalk.RevTree;
import org.eclipse.jgit.revwalk.RevWalk;
import org.eclipse.jgit.lib.Ref;

public class GitLink extends Plugin {

    static final int BLOCK_MAXLEN = 1024;

    public static HashMap<String, String> pluginInfo = null;
    public static URLClassLoader loader = null;
    public static void setLoader(URLClassLoader l) { loader = l; }
    public static void setInfo(HashMap<String, String>info) { pluginInfo = info; }
    public static String getInfo(String item) { return pluginInfo.get(item); }
    public GitLink(EditorBase e) { editorTab = e; }

    public Repository localRepo = null;
    public Git git = null;
    public File dotGit = null;

    public boolean hasRepo = false;

    public GitLink(Editor e) { 
        editor = e; 
        openRepo();
    }

    public String relative(File f) {
        URI sketch = editor.getSketch().getFolder().toURI();
        URI file = f.toURI();
        return sketch.relativize(file).getPath();
    }

    public void openRepo() {
        try {
            dotGit = new File(editor.getSketch().getFolder(), ".git");
            localRepo = new FileRepository(new File(editor.getSketch().getFolder(), ".git"));
            git = new Git(localRepo);
            if (!dotGit.exists() || !dotGit.isDirectory()) {
                return;
            }
            hasRepo = true;
        } catch (Exception e) {
            Base.error(e);
        }
    }

    public boolean createRepo() {
        try {
            if (hasRepo) {
                return false;
            }

            if (localRepo == null) {
                openRepo();
            }
            if (localRepo != null) {
                localRepo.create();
                git = new Git(localRepo);
                updateIconCache();
                editor.updateTree();
                catchEvent(UEvent.SKETCH_OPEN);

                for (File f : editor.getSketch().sketchFiles) {
                    addFile(f);
                }
                commitRepo("Initial repository creation");
                return true;
            }
        } catch (Exception e) {
            Base.error(e);
        }
        return false;
    }

    public boolean addFile(File f) {
        try {
            if (localRepo == null) {
                openRepo();
            }
            if (!hasRepo) {
                openRepo();
            }
            if (hasRepo) {
                String fn = relative(f);
                git.add().addFilepattern(fn).call();
                updateIconCache();
                editor.refreshTreeModel();
                return true;
            }
        } catch (Exception e) {
            Base.error(e);
        }
        return false;
    }

    public boolean commitRepo(String message) {
        try {
            if (localRepo == null) {
                openRepo();
            }
            if (!hasRepo) {
                openRepo();
            }
            if (hasRepo) {
                git.commit().setAll(true).setMessage(message).call();
                updateIconCache();
                editor.refreshTreeModel();
                return true;
            }
        } catch (Exception e) {
            Base.error(e);
        }
        return false;
    }

    public boolean pushRepo(String remote) {
        try {
            if (localRepo == null) {
                openRepo();
            }
            if (!hasRepo) {
                openRepo();
            }
            if (hasRepo) {
                if (remote == null) {   
                    remote = "origin";
                }
                git.push().setPushAll().setRemote(remote).call();
                updateIconCache();
                editor.refreshTreeModel();
                return true;
            }
        } catch (Exception e) {
            Base.error(e);
        }
        return false;
    }

    public boolean pullRepo(String remote) {
        try {
            if (localRepo == null) {
                openRepo();
            }
            if (!hasRepo) {
                openRepo();
            }
            if (hasRepo) {
                if (remote == null) {   
                    remote = "origin";
                }
                git.pull().setRemote(remote).call();
                updateIconCache();
                editor.refreshTreeModel();
                return true;
            }
        } catch (Exception e) {
            Base.error(e);
        }
        return false;
    }

    public boolean addRemote(String type, String url) {
        try {
            if (localRepo == null) {
                openRepo();
            }
            if (!hasRepo) {
                openRepo();
            }
            if (hasRepo) {
                StoredConfig config = git.getRepository().getConfig();
                config.setString("remote", type, "url", url);
                config.save();
                updateIconCache();
                editor.refreshTreeModel();
                return true;
            }
        } catch (Exception e) {
            Base.error(e);
        }
        return false;
    }

    public boolean hasFile(File f) {
        try {
            if (localRepo == null) {
                openRepo();
            }
            if (!hasRepo) {
                openRepo();
            }
            if (hasRepo) {
                Ref head = localRepo.getRef("HEAD");
                RevWalk walk = new RevWalk(localRepo);
                RevCommit commit = walk.parseCommit(head.getObjectId());
                RevTree tree = commit.getTree();
                TreeWalk treeWalk = new TreeWalk(localRepo);
                treeWalk.addTree(tree);
                treeWalk.setRecursive(true);
                while (treeWalk.next()) {
                    File target = new File(editor.getSketch().getFolder(), treeWalk.getPathString());
                    if (target.equals(f)) {
                        return true;
                    }
                }
            }
        } catch (Exception e) {
            Base.error(e);
        }
        return false;
    }

    public void commitAllUpdates() {
        try {
            if (localRepo == null) {
                openRepo();
            }
            if (!hasRepo) {
                openRepo();
            }
            if (hasRepo) {
                Status s = git.status().call();
                if (s.hasUncommittedChanges()) {

                    String message = (String)JOptionPane.showInputDialog(
                        editor,
                        "Enter commit message:",
                        "Push to Git repository",
                        JOptionPane.PLAIN_MESSAGE,
                        null,
                        null,
                        "");
                    if (message != null) {
                        editor.setCursor(new Cursor(Cursor.WAIT_CURSOR));
                        commitRepo(message);
                    }
                }
            }

        } catch (Exception e) {
            Base.error(e);
        }
    }

    public void createBranch() {
        try {
            if (localRepo == null) {
                openRepo();
            }
            if (!hasRepo) {
                openRepo();
            }
            if (hasRepo) {
                String name = (String)JOptionPane.showInputDialog(
                    editor,
                    "Enter branch name:",
                    "Create new branch",
                    JOptionPane.PLAIN_MESSAGE,
                    null,
                    null,
                    "");

                if (name != null) {
                    git.checkout().setName(name).setCreateBranch(true).call();
                    updateIconCache();
                    editor.refreshTreeModel();
                }
            }
        } catch (Exception e) {
            Base.error(e);
        }
    }

    public void populateMenu(JMenu menu, int flags) {
    }

    public void populateContextMenu(JPopupMenu menu, int flags, DefaultMutableTreeNode node) {
        if (localRepo == null) {
            openRepo();
        }
        if (!hasRepo) {
            openRepo();
        }
        if (hasRepo) {
            if (
                (flags == (Plugin.MENU_TREE_FILE | Plugin.MENU_TOP)) ||
                (flags == (Plugin.MENU_FILE_FILE | Plugin.MENU_TOP)) 
            ) {
                Object o = node.getUserObject();
                if (o instanceof File) {
                    File f = (File)o;
                    if (!hasFile(f)) {
                        JMenuItem item = new JMenuItem("Add to Git repository");
                        item.addActionListener(new ActionListener() {
                            public void actionPerformed(ActionEvent e) {
                               addFile(new File(e.getActionCommand()));
                            }
                        });
                        item.setActionCommand(f.getAbsolutePath());
                        menu.add(item);
                    }
                }
            }
        } else {
            if  (flags == (Plugin.MENU_TREE_SKETCH | Plugin.MENU_TOP)) {
                JMenuItem item = new JMenuItem("Create Git Repository");
                item.addActionListener(new ActionListener() {
                    public void actionPerformed(ActionEvent e) {
                        createRepo();
                    }
                });
                menu.add(item);
            }
        }
    }

    public void createRemote() {
        final JDialog dia = new JDialog(editor, "Add new remote repository", Dialog.ModalityType.APPLICATION_MODAL);
        dia.setLayout(new GridBagLayout());
        JPanel p = (JPanel)dia.getContentPane();
        p.setBorder(BorderFactory.createEmptyBorder(5, 5, 5, 5));
        GridBagConstraints c = new GridBagConstraints();
        c.gridwidth = 3;
        c.gridheight = 1;
        c.weightx = 0.5;
        c.fill = GridBagConstraints.HORIZONTAL;
        c.gridx = 0;
        c.gridy = 0;
        JLabel lab = new JLabel("Repository name:");
        p.add(lab, c);

        final JTextField remName = new JTextField(40);
        remName.setText("upstream");
        c.gridy++;
        p.add(remName, c);

        lab = new JLabel("Remote URI:");
        c.gridy++;
        p.add(lab, c);

        final JTextField remURI = new JTextField(40);
        remURI.setText("git@github.com:<username>/<repository>");
        c.gridy++;
        p.add(remURI, c);

        c.gridwidth = 1;
        c.gridy++;

        c.gridx = 0;
        lab = new JLabel("");
        c.weightx = 0.8;
        p.add(lab, c);

        c.gridx = 1;
        JButton can = new JButton("Cancel");
        can.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent bae) {
                dia.dispose();
            }
        });
        c.weightx = 0.1;
        p.add(can, c);

        c.gridx = 2;
        JButton add = new JButton("Add");
        add.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent bae) {
                addRemote(remName.getText(), remURI.getText());
                dia.dispose();
            }
        });
        c.weightx = 0.1;
        p.add(add, c);

        dia.pack();
        dia.setLocationRelativeTo(editor);
        dia.setVisible(true);
    }

    private JButton pullButton = null;
    private JButton pushButton = null;
    private JButton commitButton = null;
    private JButton branchButton = null;

    public void addToolbarButtons(JToolBar toolbar, int flags) {
        if (flags == Plugin.TOOLBAR_EDITOR) {
            toolbar.addSeparator();
            hasFile(null);
            pullButton = new JButton(Base.loadIconFromResource("uecide/plugin/GitLink/pull.png", loader));
            pullButton.setToolTipText("Pull from remote repository");
            pullButton.addActionListener(new ActionListener() {
                public void actionPerformed(ActionEvent e) {
                    try {
                        if (localRepo == null) {
                            openRepo();
                        }
                        if (!hasRepo) {
                            openRepo();
                        }
                        if (hasRepo) {
                            JPopupMenu menu = new JPopupMenu();
                            Point pos = pullButton.getLocation();
                            Dimension size = branchButton.getSize();

                            JMenuItem item = new JMenuItem("Pull from remote");
                            item.setEnabled(false);
                            menu.add(item);
                            menu.addSeparator();

                            StoredConfig config = git.getRepository().getConfig();
                            Set<String> remotes = config.getSubsections("remote");
                            for (String s : remotes) {
                                item = new JMenuItem(s + " (" + config.getString("remote", s, "url") + ")");
                                item.setActionCommand(s);
                                item.addActionListener(new ActionListener() {
                                    public void actionPerformed(ActionEvent ev) {
                                        editor.setCursor(new Cursor(Cursor.WAIT_CURSOR));
                                        pullRepo(ev.getActionCommand());
                                        editor.setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
                                    }
                                });
                                menu.add(item);
                            }

                            menu.addSeparator();
                            item = new JMenuItem("Add new remote");
                            item.addActionListener(new ActionListener() {
                                public void actionPerformed(ActionEvent ev) {
                                    createRemote();
                                }
                            });
                            menu.add(item);
        
                            menu.show(pullButton, 0, size.height);
                        }
                    } catch (Exception ex) {
                        Base.error(ex);
                    }
                }
            });
            toolbar.add(pullButton);
            pullButton.setEnabled(hasRepo);


            pushButton = new JButton(Base.loadIconFromResource("uecide/plugin/GitLink/push.png", loader));
            pushButton.setToolTipText("Push to remote repository");
            pushButton.addActionListener(new ActionListener() {
                public void actionPerformed(ActionEvent e) {
                    try {
                        if (localRepo == null) {
                            openRepo();
                        }
                        if (!hasRepo) {
                            openRepo();
                        }
                        if (hasRepo) {
                            JPopupMenu menu = new JPopupMenu();
                            Point pos = pushButton.getLocation();
                            Dimension size = branchButton.getSize();

                            JMenuItem item = new JMenuItem("Push to remote");
                            item.setEnabled(false);
                            menu.add(item);
                            menu.addSeparator();

                            StoredConfig config = git.getRepository().getConfig();
                            Set<String> remotes = config.getSubsections("remote");
                            for (String s : remotes) {
                                item = new JMenuItem(s + " (" + config.getString("remote", s, "url") + ")");
                                item.setActionCommand(s);
                                item.addActionListener(new ActionListener() {
                                    public void actionPerformed(ActionEvent ev) {
                                        editor.setCursor(new Cursor(Cursor.WAIT_CURSOR));
                                        pushRepo(ev.getActionCommand());
                                        editor.setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
                                    }
                                });
                                menu.add(item);
                            }

                            menu.addSeparator();
                            item = new JMenuItem("Add new remote");
                            item.addActionListener(new ActionListener() {
                                public void actionPerformed(ActionEvent ev) {
                                    createRemote();
                                }
                            });
                            menu.add(item);
        
                            menu.show(pushButton, 0, size.height);
                        }
                    } catch (Exception ex) {
                        Base.error(ex);
                    }
                }
            });
            toolbar.add(pushButton);
            pushButton.setEnabled(hasRepo);

            commitButton = new JButton(Base.loadIconFromResource("uecide/plugin/GitLink/commit.png", loader));
            commitButton.setToolTipText("Commit all changes");
            commitButton.addActionListener(new ActionListener() {
                public void actionPerformed(ActionEvent e) {
                    commitAllUpdates();
                    editor.setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
                }
            });
            toolbar.add(commitButton);
            commitButton.setEnabled(hasRepo);

            branchButton = new JButton(Base.loadIconFromResource("uecide/plugin/GitLink/branch.png", loader));
            branchButton.setToolTipText("Branch");
            branchButton.addActionListener(new ActionListener() {
                public void actionPerformed(ActionEvent e) {
                    try {
                        if (localRepo == null) {
                            openRepo();
                        }
                        if (!hasRepo) {
                            openRepo();
                        }
                        if (hasRepo) {
                            JPopupMenu menu = new JPopupMenu();
                            Point pos = branchButton.getLocation();
                            Dimension size = branchButton.getSize();

                            JMenuItem item = new JMenuItem("Create new branch");
                            item.addActionListener(new ActionListener() {
                                public void actionPerformed(ActionEvent ev) {
                                    createBranch();
                                    editor.setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
                                }
                            });
                            menu.add(item);
                            menu.addSeparator();
                            item = new JMenuItem("Switch to branch:");
                            item.setEnabled(false);
                            menu.add(item);
                            menu.addSeparator();

                            String currentBranch = localRepo.getBranch();
                            final List<Ref> branches = git.branchList().call();
                            ButtonGroup bg = new ButtonGroup();
                            for (Ref r : branches) {
                                String bname = r.getName();
                                bname = bname.substring(bname.lastIndexOf("/") + 1);
                                item = new JRadioButtonMenuItem(bname);
                                if (bname.equals(currentBranch)) {
                                    item.setSelected(true);
                                }
                                item.setActionCommand(r.getName());
                                item.addActionListener(new ActionListener() {
                                    public void actionPerformed(ActionEvent ae) {
                                        try {
                                            Status s = git.status().call();
                                            if (s.hasUncommittedChanges()) {
                                                JOptionPane.showMessageDialog(editor, "You have uncommitted changes.", "Cannot switch branches", JOptionPane.ERROR_MESSAGE);
                                            } else {
                                                editor.setCursor(new Cursor(Cursor.WAIT_CURSOR));
                                                git.checkout().setName(ae.getActionCommand()).call();
                                                editor.getSketch().rescanFileTree();
                                                editor.updateTree();
                                                editor.setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
                                            }
                                        } catch (Exception aexa) {
                                            Base.error(aexa);
                                        }
                                    }
                                });
                                bg.add(item);
                                menu.add(item);
                            }
                            menu.addSeparator();
                            JMenu sub = new JMenu("Merge branch");
                            for (Ref r : branches) {
                                String bname = r.getName();
                                bname = bname.substring(bname.lastIndexOf("/") + 1);
                                if (!(bname.equals(currentBranch))) {
                                    item = new JMenuItem(bname);
                                    sub.add(item);
                                    item.setActionCommand(r.getName());
                                    item.addActionListener(new ActionListener() {
                                        public void actionPerformed(ActionEvent ae) {
                                            try {
                                                Status s = git.status().call();
                                                if (s.hasUncommittedChanges()) {
                                                    JOptionPane.showMessageDialog(editor, "You have uncommitted changes.", "Cannot switch branches", JOptionPane.ERROR_MESSAGE);
                                                } else {
                                                    editor.setCursor(new Cursor(Cursor.WAIT_CURSOR));
                                                    for (Ref r : branches) {
                                                        if (r.getName().equals(ae.getActionCommand())) {
                                                            git.merge().include(r).call();
                                                            break;
                                                        }
                                                    }
                                                    editor.getSketch().rescanFileTree();
                                                    editor.updateTree();
                                                    editor.setCursor(new Cursor(Cursor.DEFAULT_CURSOR));
                                                }
                                            } catch (Exception aexa) {
                                                Base.error(aexa);
                                            }
                                        }
                                    });
                                }
                            }
                            
                            menu.add(sub);
                            menu.show(branchButton, 0, size.height);
                        }
                    } catch (Exception ex) {
                        Base.error(ex);
                    }
                }
 
            });

            toolbar.add(branchButton);
            branchButton.setEnabled(hasRepo);

            toolbar.addSeparator();
        }
    }

    public static void populatePreferences(JPanel p) {
    }

    public static String getPreferencesTitle() {
        return "Git Link";
    }

    public static void savePreferences() {
    }

    public HashMap<File, ImageIcon> iconCache = new HashMap<File, ImageIcon>();
    public long lastCacheUpdate = 0;

    public ImageIcon getFileIconOverlay(File f) {
        try {
            if (localRepo == null) {
                openRepo();
            }
            if (!hasRepo) {
                openRepo();
            }
            if (hasRepo) {

                if (System.currentTimeMillis() - lastCacheUpdate > 10L) {
                    lastCacheUpdate = System.currentTimeMillis();
                    updateIconCache();
                }

                ImageIcon cached = iconCache.get(f);
                if (cached != null) {
                    return cached;
                }

            }
        } catch (Exception e) {
            Base.error(e);
        }
        return null;
    }

    public void updateIconCache() {
        try {
            iconCache = new HashMap<File, ImageIcon>();
            if (localRepo == null) {
                openRepo();
            }
            if (!hasRepo) {
                openRepo();
            }
            if (hasRepo) {
                Status s = git.status().call();
                Set<String> added = s.getAdded();
                Set<String> changed = s.getChanged();
                Set<String> missing = s.getMissing();
                Set<String> modified = s.getModified();
                Set<String> untracked = s.getUntracked();

                for (String str : added) { 
                    File file = new File(editor.getSketch().getFolder(), str);
                    ImageIcon i = Base.loadIconFromResource("uecide/plugin/GitLink/vcs-added.png", loader);
                    iconCache.put(file, i);
                }
                    
                for (String str : changed) { 
                    File file = new File(editor.getSketch().getFolder(), str);
                    ImageIcon i = Base.loadIconFromResource("uecide/plugin/GitLink/vcs-locally-modified-not-staged.png", loader);
                    iconCache.put(file, i);
                }
                    
                for (String str : missing) { 
                    File file = new File(editor.getSketch().getFolder(), str);
                    ImageIcon i = Base.loadIconFromResource("uecide/plugin/GitLink/vcs-locally-modified-not-staged.png", loader);
                    iconCache.put(file, i);
                }
                    
                for (String str : modified) { 
                    File file = new File(editor.getSketch().getFolder(), str);
                    ImageIcon i = Base.loadIconFromResource("uecide/plugin/GitLink/vcs-locally-modified.png", loader);
                    iconCache.put(file, i);
                }
                    
                for (String str : untracked) { 
                    File file = new File(editor.getSketch().getFolder(), str);
                    ImageIcon i = Base.loadIconFromResource("uecide/plugin/GitLink/vcs-conflicting.png", loader);
                    iconCache.put(file, i);
                }
            }
        } catch (Exception e) {
            Base.error(e);
        }
    }

    public void catchEvent(int event) {
        if (event == UEvent.SKETCH_OPEN) {
            openRepo();
            updateIconCache();
            pullButton.setEnabled(hasRepo);
            pushButton.setEnabled(hasRepo);
            commitButton.setEnabled(hasRepo);
            branchButton.setEnabled(hasRepo);
        }
    }
}