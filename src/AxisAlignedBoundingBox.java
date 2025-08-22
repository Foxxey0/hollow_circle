public class AxisAlignedBoundingBox {

    protected float xMin;
    protected float xMax;
    protected float yMin;
    protected float yMax;

    protected int xMin_INT;
    protected int xMax_INT;
    protected int yMin_INT;
    protected int yMax_INT;

    protected int xMin_INT_clamped;
    protected int xMax_INT_clamped;
    protected int yMin_INT_clamped;
    protected int yMax_INT_clamped;

    public int parentWidth;
    public int parentHeight;

    public AxisAlignedBoundingBox() {
        this.xMin = 0;
        this.xMax = 0;
        this.yMin = 0;
        this.yMax = 0;
        this.xMin_INT = 0;
        this.xMax_INT = 0;
        this.yMin_INT = 0;
        this.yMax_INT = 0;
        this.xMin_INT_clamped = 0;
        this.xMax_INT_clamped = 0;
        this.yMin_INT_clamped = 0;
        this.yMax_INT_clamped = 0;
        this.parentWidth = 0;
        this.parentHeight = 0;
    }

    public AxisAlignedBoundingBox(float xMin, float xMax, float yMin, float yMax, int parentWidth, int parentHeight) {
        this.xMin = xMin;
        this.xMax = xMax;
        this.yMin = yMin;
        this.yMax = yMax;
        this.parentWidth = parentWidth;
        this.parentHeight = parentHeight;

        convertToInts();
        clamp();

    }

    protected void convertToInts() {
        xMin_INT = (int) xMin +1;
        xMax_INT = (int) xMax;
        yMin_INT = (int) yMin +1;
        yMax_INT = (int) yMax;
    }

    private void clamp() {
        xMin_INT_clamped = Math.min(Math.max(xMin_INT, 0), parentWidth -1);
        xMax_INT_clamped = Math.min(Math.max(xMax_INT, 0), parentWidth -1);
        yMin_INT_clamped = Math.min(Math.max(yMin_INT, 0), parentHeight -1);
        yMax_INT_clamped = Math.min(Math.max(yMax_INT, 0), parentHeight -1);
    }

    public float getxMin() {
        return xMin;
    }

    public void setxMin(float xMin) {
        this.xMin = xMin;
        xMin_INT = (int) xMin +1; // set the INT version
        xMin_INT_clamped = Math.min(Math.max(xMin_INT, 0), parentWidth -1); // set the clamped INT version
    }

    public float getxMax() {
        return xMax;
    }

    public void setxMax(float xMax) {
        this.xMax = xMax;
        xMax_INT = (int) xMax; // set the INT version
        xMax_INT_clamped = Math.min(Math.max(xMax_INT, 0), parentWidth -1); // set the clamped INT version
    }

    public float getyMin() {
        return yMin;
    }

    public void setyMin(float yMin) {
        this.yMin = yMin;
        yMin_INT = (int) yMin +1; // set the INT version
        yMin_INT_clamped = Math.min(Math.max(yMin_INT, 0), parentHeight -1); // set the clamped INT version
    }

    public float getyMax() {
        return yMax;
    }

    public void setyMax(float yMax) {
        this.yMax = yMax;
        yMax_INT = (int) yMax; // set the INT version
        yMax_INT_clamped = Math.min(Math.max(yMax_INT, 0), parentHeight -1); // set the clamped INT version
    }

    public int getxMin_INT() {
        return xMin_INT;
    }

    public int getxMax_INT() {
        return xMax_INT;
    }

    public int getyMin_INT() {
        return yMin_INT;
    }

    public int getyMax_INT() {
        return yMax_INT;
    }

    public int getxMin_INT_clamped() {
        return xMin_INT_clamped;
    }

    public int getxMax_INT_clamped() {
        return xMax_INT_clamped;
    }

    public int getyMin_INT_clamped() {
        return yMin_INT_clamped;
    }

    public int getyMax_INT_clamped() {
        return yMax_INT_clamped;
    }
}
